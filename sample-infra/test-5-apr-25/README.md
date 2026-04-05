# sample-infra/test-5-apr-25

This Terraform project creates a **real-time looking AWS infrastructure** for a containerized application similar to [Kyverno Policy Reporter](https://github.com/kyverno/policy-reporter).

## What this deploys

- VPC with:
  - 2 public subnets (for ALB + NAT)
  - 2 private subnets (for ECS tasks)
  - Internet Gateway + NAT Gateway
- ECS Fargate cluster + service running `ghcr.io/kyverno/policy-reporter:latest`
- Application Load Balancer exposing HTTP endpoint
- CloudWatch log group for container logs
- ECS Service autoscaling (CPU target tracking)
- CloudWatch dashboard for ALB requests and ECS CPU

## Quick start

```bash
cd sample-infra/test-5-apr-25
terraform init
cp terraform.tfvars.example terraform.tfvars
terraform plan
terraform apply
```

## Notes

- This is intentionally production-like, but simplified for learning/demo purposes.
- ALB listener is HTTP only; add ACM + HTTPS for production.
- Ensure your AWS account has quotas for NAT Gateway, ALB, and ECS Fargate.

## Cleanup

```bash
terraform destroy
```
