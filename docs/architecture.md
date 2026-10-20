# Architecture

## Network (prod defaults)

| Layer | CIDRs (per AZ a/b/c) | Route to internet |
|---|---|---|
| Public | 10.1.0.0/24, 10.1.1.0/24, 10.1.2.0/24 | Internet gateway |
| Private app | 10.1.10.0/24, 10.1.11.0/24, 10.1.12.0/24 | NAT gateway in the same AZ |
| Private data | 10.1.20.0/24, 10.1.21.0/24, 10.1.22.0/24 | None |

Dev uses `10.0.0.0/16` with the same layout. Prod uses `10.1.0.0/16` so the two can be peered later.

## Traffic and security groups

```
Internet -> ALB SG (80, 443 from allowed CIDRs)
         -> App SG (8080 from ALB SG only)
         -> DB SG  (3306 from App SG only)
```

- The default VPC security group has no rules.
- The database has no inbound path except from the application security group, and no outbound rules.
- ECS tasks have no public IPs. Outbound goes through NAT or VPC endpoints.

## Components

| Component | Notes |
|---|---|
| ALB | HTTP listener; HTTPS listener and HTTP-to-HTTPS redirect are enabled by setting `certificate_arn` |
| ECS Fargate | Rolling deployments (min 100%, max 200%), circuit breaker with automatic rollback, CPU and request-count autoscaling |
| RDS MySQL 8.4 | Encrypted with a customer-managed KMS key, master password managed by RDS in Secrets Manager, TLS required, slow-query and error logs exported |
| ECR | Immutable tags (commit SHA), scan on push, lifecycle policy |
| Monitoring | 10 CloudWatch alarms and a dashboard, SNS email notifications |
| CI/CD | GitHub Actions with OIDC; role limited to one ECR repo and one ECS service |
| Rotation restart | Lambda that restarts the ECS service after the database secret rotates, so tasks never keep a stale password |
| Account baseline | CloudTrail (multi-region, validated), GuardDuty with email alerts, monthly budget, S3 public-access block |

## Design decisions

| Decision | Why | Trade-off |
|---|---|---|
| ECS Fargate | No servers to patch, native rolling deploys and autoscaling | Costs more per vCPU than EC2 at high, steady load |
| One NAT gateway per AZ (prod) | An AZ failure does not cut off the other AZs | About three times the NAT cost of a single gateway |
| VPC endpoints (ECR, Logs, Secrets Manager, S3) | Keeps AWS API traffic private and off the NAT | Interface endpoints bill hourly per AZ |
| RDS-managed master secret | Password never in code or state | Rotation breaks running tasks unless they restart; handled by the rotation-restart module (see runbook, section 9) |
| Immutable image tags | A deployed tag can never be silently replaced | Re-running a build for the same commit reuses the existing image |
| Separate state per environment | A mistake in dev cannot touch prod | More files to manage |
| Account baseline as its own stack | Guardrails belong to the account, not the app | One more state file |

## Environments

| | dev | prod |
|---|---|---|
| NAT gateways | 1 | 3 |
| Interface endpoints | off | on |
| Database | db.t4g.micro, single-AZ, 1-day backups, no deletion protection | db.t4g.medium, Multi-AZ, 14-day backups, deletion protection, final snapshot |
| App tasks | 1 (max 2) | 2 minimum (max 6) |
| ALB deletion protection | off | on |

`infra/envs/prod/practice.tfvars` applies dev-like settings to the prod code for rehearsal.
Never use it for a real production deployment.

## Future work
HTTPS and WAF, least-privilege application database user, GitHub Environment approval for prod
deploys, cross-region backup copy, and ALB access logs.
