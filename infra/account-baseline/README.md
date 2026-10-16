# account-baseline

Per-account security and cost guardrails, separate from the application stacks
(its own state: three-tier/account-baseline/terraform.tfstate).

| Control | What it gives the client |
|---|---|
| CloudTrail (multi-region, log validation, encrypted, 365 days) | Audit trail of every API call: who changed what, when |
| GuardDuty + email on severity >= 4 | Threat detection (compromised keys, crypto-mining, odd API use) |
| AWS Budget (80% actual, 100% forecast) | No surprise bills |
| S3 account-level public access block | A bucket can never be made public by mistake |

Before applying, check what the account already has (only one GuardDuty detector per region):

    aws guardduty list-detectors --region eu-north-1
    aws cloudtrail describe-trails --region eu-north-1 --query "trailList[].Name"

If a detector exists:   -var enable_guardduty=false
If you already have a trail:   -var create_cloudtrail=false

    cd infra/account-baseline
    cp backend.hcl.example backend.hcl        # set bucket
    echo 'alert_email = "you@example.com"' > terraform.tfvars
    terraform init -backend-config=backend.hcl
    terraform plan -out tfplan
