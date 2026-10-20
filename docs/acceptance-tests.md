# Acceptance tests

Run these with the client present, in the client's account, before sign-off.
Fill in the Result and Date columns.

| # | Test | How | Expected | Result | Date |
|---|---|---|---|---|---|
| 1 | Site responds | `curl -i http://<alb-dns>/api/hello` | 200 and a JSON message | | |
| 2 | Health includes database | `curl http://<alb-dns>/actuator/health` | `{"status":"UP"}` | | |
| 3 | Write and read data | POST then GET `/api/notes` | Note is returned | | |
| 4 | Data survives restart | `ecs update-service --force-new-deployment`, then GET `/api/notes` | Note still present | | |
| 5 | Task failure recovery | Stop one task in the console | ECS starts a replacement; no downtime with 2+ tasks | | |
| 6 | Bad deploy rolls back | Deploy an image that fails health checks | Circuit breaker restores the previous version | | |
| 7 | Pipeline end-to-end | Change a visible message, push to `main` | New message live; no manual AWS steps | | |
| 8 | Alert delivery | `aws cloudwatch set-alarm-state --alarm-name threetier-ENV-app-5xx --state-value ALARM --state-reason test` | Email received by the alert address | | |
| 9 | Database restore | Point-in-time restore to a new instance (runbook, section 8) | Restored data verified | | |
| 10 | Secret rotation | `aws secretsmanager rotate-secret`, wait 5 minutes, then GET `/api/notes` repeatedly for 40 minutes | A rolling deployment starts by itself (check the Lambda logs); `/api/notes` keeps returning 200 | | |
| 11 | Autoscaling | Generate load against the ALB | Task count increases, then decreases | | |
| 12 | Rebuild from code | `terraform apply` in an empty environment | Stack is recreated and tests 1 to 3 pass | | |
| 13 | Security baseline | Check CloudTrail, GuardDuty, and the budget in the console | All active; confirmation emails accepted | | |
| 14 | Access review | Compare IAM users and roles with `access-and-ownership.md` | No unknown access; no root access keys; MFA on root | | |

Sign-off: ______________________  Client: ______________________  Date: __________
