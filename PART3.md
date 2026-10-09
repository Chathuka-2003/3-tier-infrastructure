# Part 3: Monitoring (alarms + dashboard + email alerts)

New files only:
```
infra/modules/monitoring/            SNS topic, 10 alarms, CloudWatch dashboard
infra/modules/rds/outputs_monitoring.tf   exposes the DB identifier
infra/envs/dev/monitoring.tf, monitoring_variables.tf, monitoring_outputs.tf
```

## Deploy
```bash
cd infra/envs/dev
echo 'alert_email = "you@example.com"' >> terraform.tfvars   # your real address
terraform init
terraform fmt -recursive ../..
terraform validate
terraform plan -out tfplan
terraform apply "tfplan"
```
Then open the confirmation email from AWS Notifications and click "Confirm subscription".

## Test the alarms
```bash
export AWS_REGION=eu-north-1
aws cloudwatch set-alarm-state --alarm-name threetier-dev-app-5xx \
  --state-value ALARM --state-reason "manual test"
```
You should get an email within a minute. The alarm returns to OK by itself at the next evaluation.
