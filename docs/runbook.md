# Operations runbook

All commands assume:

```bash
export AWS_REGION=eu-north-1
ENV=prod                              # or dev
CLUSTER=threetier-$ENV-cluster
SERVICE=threetier-$ENV-app
```

## Resource names

| Resource | Name |
|---|---|
| ECS cluster / service / task family | `threetier-ENV-cluster` / `threetier-ENV-app` / `threetier-ENV-app` |
| Log group | `/ecs/threetier-ENV` |
| ECR repository | `threetier-ENV-app` |
| Load balancer | `threetier-ENV-alb` |
| Database | `threetier-ENV-mysql` (subnet group `threetier-ENV-db`) |
| Alerts topic / dashboard | `threetier-ENV-alerts` / `threetier-ENV` |
| Deploy role (GitHub) | `threetier-ENV-github-deploy` |

## 1. Is it healthy?

```bash
aws ecs describe-services --cluster $CLUSTER --services $SERVICE \
  --query "services[0].{desired:desiredCount,running:runningCount,pending:pendingCount,rollout:deployments[].[status,rolloutState]}"

LB_ARN=$(aws elbv2 describe-load-balancers --names threetier-$ENV-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
TG_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $LB_ARN --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output table

ALB=$(aws elbv2 describe-load-balancers --names threetier-$ENV-alb --query 'LoadBalancers[0].DNSName' --output text)
curl -s http://$ALB/actuator/health        # {"status":"UP"} also proves the database connection
```

Also open the CloudWatch dashboard `threetier-ENV`.

## 2. Logs

```bash
aws logs tail /ecs/threetier-$ENV --since 30m --follow
```

## 3. Deploy

Merge to `main`. The `build-and-deploy` workflow builds, pushes to ECR, and rolls out.
Watch the Actions tab. The rollout waits up to 15 minutes for the service to become stable.
A failed rollout rolls back automatically.

## 4. Roll back a bad release

Preferred (keeps history): revert the commit on `main`; the pipeline redeploys the previous code.

Emergency (immediate), switch the service to the previous task definition revision:

```bash
aws ecs list-task-definitions --family-prefix threetier-$ENV-app --sort DESC --max-items 5
aws ecs update-service --cluster $CLUSTER --service $SERVICE --task-definition threetier-$ENV-app:<REVISION>
```

## 5. Restart or replace tasks

```bash
aws ecs update-service --cluster $CLUSTER --service $SERVICE --force-new-deployment
```

## 6. Scale

Permanent: change `ecs_min_capacity`, `ecs_max_capacity`, `ecs_cpu`, or `ecs_memory` in
`infra/envs/ENV`, then `terraform plan` and `apply`.
Temporary: `aws ecs update-service ... --desired-count N` (autoscaling may adjust it again).

## 7. Alarm response

| Alarm (`threetier-ENV-...`) | Meaning | First checks |
|---|---|---|
| `no-healthy-targets` | Site is down | Section 1; logs; recent deploy? roll back (section 4) |
| `unhealthy-targets` | A task fails health checks | Logs for that task; database reachable? |
| `app-5xx` | App returning errors | Logs; recent deploy; database alarms |
| `slow-responses` | High latency | `ecs-cpu-high`, `db-cpu-high`, slow-query log |
| `ecs-cpu-high` / `ecs-memory-high` | Tasks under pressure | Autoscaling status; raise limits (section 6) |
| `db-cpu-high` / `db-connections-high` | Database busy | Slow-query log export in CloudWatch; connection pool settings |
| `db-free-storage-low` | Disk filling | Storage autoscaling is enabled up to 100 GiB; raise `max_allocated_storage` |
| `db-free-memory-low` | Database memory pressure | Instance class too small |

## 8. Database

The database has no public access and no bastion by design. For administration, enable ECS Exec
on the service (not enabled by default) or use a short-lived bastion in the app subnets.
Credentials live in Secrets Manager (`terraform output db_secret_arn`).

### Restore from backup (rehearse this before relying on it)

Backups: 14 days automated in prod (1 day in dev). Point-in-time restore creates a NEW instance:

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier threetier-$ENV-mysql \
  --target-db-instance-identifier threetier-$ENV-mysql-restore \
  --use-latest-restorable-time \
  --db-subnet-group-name threetier-$ENV-db \
  --vpc-security-group-ids <DB_SECURITY_GROUP_ID> \
  --db-parameter-group-name <PARAMETER_GROUP_NAME>
```

Then validate the restored data. To cut over without changing the app, rename the original instance
to `...-old` and the restored one to the original identifier. Afterwards reconcile Terraform state
(`terraform state rm` and `terraform import` for `module.rds.aws_db_instance.this`).

## 9. Database secret rotation

RDS rotates the managed master password on a schedule (7 days by default). ECS injects the secret
only when a task starts, so a task that started before a rotation holds a stale password.

**Measured in dev (16 Oct 2026):** the secret rotated at 10:56 IST. Between 11:05 and 11:35 IST the
task logged `Access denied for user 'dbadmin'` and `HikariPool-1 - Connection is not available`;
the task was replaced at 11:16. Existing connections keep working until the pool retires them
(about 30 minutes), then the application cannot reconnect.

**Fix in place:** the `rotation-restart` module runs a small Lambda every 2 minutes. If the secret
was rotated after the service's current deployment was created, it starts a rolling deployment,
so new tasks read the current password. Errors from the function raise the
`...-restart-on-rotation-errors` alarm.

Check what the function is doing:
```bash
aws logs tail /aws/lambda/threetier-$ENV-restart-on-rotation --since 30m
aws secretsmanager list-secrets --query "SecretList[?starts_with(Name,'rds!db')].[Name,LastRotatedDate]" --output table
```

Manual recovery if the function is disabled or failing:
```bash
aws ecs update-service --cluster $CLUSTER --service $SERVICE --force-new-deployment
```

Residual risk: for up to a few minutes after a rotation (check interval plus rollout time) a task can
return errors. A dedicated application database user that is not auto-rotated would remove this
risk entirely and is recommended for production.

## 10. Other known risks

HTTP only until a certificate exists; the deploy role trusts any push to `main`; the application
connects with the master credentials.
