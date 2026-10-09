# Part 2: ECR + ALB + ECS Fargate

New files only (nothing you already have is overwritten):

```
infra/modules/ecr/        image registry (scan on push, immutable tags, lifecycle)
infra/modules/alb/        public load balancer, target group, HTTP (HTTPS ready)
infra/modules/ecs/        cluster, task definition, service, autoscaling, IAM
infra/envs/dev/app.tf            wires the three modules to your network + RDS
infra/envs/dev/app_variables.tf  image, port, health path, scaling
infra/envs/dev/app_outputs.tf    alb_dns_name, ecr_repository_url, ...
```

## Deploy
```bash
cd infra/envs/dev
terraform init            # picks up the 3 new modules
terraform fmt -recursive ../..
terraform validate
terraform plan -out tfplan
terraform apply "tfplan"
```

## Test the placeholder (nginx)
```bash
curl -i http://$(terraform output -raw alb_dns_name)
```
Wait 1-3 minutes after apply. You should see `HTTP/1.1 200 OK` and the nginx welcome page.

## Switch to your real Spring Boot image
```bash
export AWS_REGION=eu-north-1
ECR=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR%%/*}

# from the folder with your Dockerfile
docker build --platform linux/amd64 -t $ECR:v1 .
docker push $ECR:v1

cd infra/envs/dev
terraform apply \
  -var container_image=$ECR:v1 \
  -var container_port=8080 \
  -var health_check_path=/actuator/health
```
