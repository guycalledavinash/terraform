# Terraform infrastructure projects

This repository contains hands-on Terraform projects for provisioning and documenting cloud infrastructure.

## Included infrastructure

- `sample-infra-fifa/` — AWS infrastructure for the GoalHub FIFA app, including:
  - networking with a VPC and load balancer;
  - ECS Fargate frontend and backend services;
  - an RDS PostgreSQL database and Secrets Manager integration;
  - S3 and CloudFront media delivery;
  - CloudWatch observability.

## Working with a project

Open the project directory you want to use, review its variables and provider configuration, then run `terraform init` and `terraform plan` before applying any changes.

## Continuous integration

GitHub Actions automatically checks Terraform changes on pushes and pull requests to `main`. The workflow verifies formatting and initializes and validates each Terraform project without configuring a backend, creating a plan, or accessing cloud infrastructure.
