# envs/prod

Same modules as dev, with production settings as the DEFAULTS:
3 NAT gateways, VPC endpoints, Multi-AZ MySQL with 14-day backups, deletion protection,
2+ tasks with autoscaling to 6, Container Insights, 30-day logs.

`practice.tfvars` overrides the expensive/restricted settings for rehearsal only.

## Plan only (free)
    cd infra/envs/prod
    cp backend.hcl.example backend.hcl        # set bucket; key already differs from dev
    terraform init -backend-config=backend.hcl
    terraform plan -var-file=practice.tfvars -var container_image=<any image URL>

## First deployment order (the image must exist before the service starts)
    terraform apply -target=module.ecr -var-file=... -var container_image=placeholder
    # push an image to the new prod ECR repo (or run the pipeline against it)
    terraform apply -var-file=... -var container_image=<ecr-url>:<tag>
