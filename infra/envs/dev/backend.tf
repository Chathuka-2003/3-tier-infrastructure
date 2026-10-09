# Partial configuration: values live in backend.hcl (copy backend.hcl.example).
# Init with:  terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {}
}
