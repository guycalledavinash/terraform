# GoalHub FIFA AWS infrastructure

This folder contains a production-looking AWS Terraform stack for the GoalHub FIFA app, a containerized 3-tier soccer dashboard with a React/Vite frontend, FastAPI backend, and PostgreSQL database.

## What it creates

- Multi-AZ VPC with public, private application, and private database subnets.
- Internet-facing Application Load Balancer that sends UI traffic to the frontend service and `/api/*`, `/docs`, `/openapi.json`, and `/health` to the backend service.
- ECS Fargate cluster with separate frontend and backend services for FIFA-season traffic.
- RDS PostgreSQL for teams, players, matches, competitions, users, and app metadata.
- Secrets Manager secret for the FastAPI JWT signing key.
- Private S3 bucket and CloudFront distribution for team crests, player photos, and match media.
- CloudWatch log groups, ECS Container Insights, autoscaling for backend API tasks, and a 5xx alarm.

## Architecture

```text
fans
  │
  ▼
Application Load Balancer ── / ─────────────► ECS Fargate frontend (React/Vite)
  │
  └── /api/*, /docs, /health ───────────────► ECS Fargate backend (FastAPI)
                                                │
                                                ├──► RDS PostgreSQL
                                                └──► Secrets Manager

S3 private media bucket ──► CloudFront CDN ──► public media delivery
```

## Deploy

1. Build and push the GoalHub frontend and backend images to ECR.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and update image URIs and secrets.
3. Run:

```bash
terraform init
terraform plan
terraform apply
```

## Notes

- Defaults are suitable for a realistic demo or seasonal non-production environment, not a hardened production launch.
- Replace the default passwords and JWT secret through `terraform.tfvars`, CI variables, or `TF_VAR_*` environment variables.
- Add ACM and Route 53 resources if you want a custom HTTPS domain for the FIFA season.
- The sample frontend image default is `nginx` and the backend default is `python` only so `terraform plan` works before application images exist. Real deployments should use the GoalHub images.
