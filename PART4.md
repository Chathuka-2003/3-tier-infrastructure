# Part 4: CI/CD with GitHub Actions (OIDC)

New: infra/modules/github-oidc, infra/envs/dev/github_*.tf, .github/workflows/*, .gitignore

Flow:  push to main -> build image -> push to ECR (tag = commit SHA) -> new ECS task
definition -> rolling update -> wait until healthy (auto-rollback on failure) -> smoke test.
Pull requests only build the image. No AWS keys are stored in GitHub.
