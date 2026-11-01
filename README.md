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


## Terraform security scanning

The GitHub Actions `security-scan` job runs Checkov `3.4.0` against `airbnb-infra-spoof/` only. The report is informational for now: findings do not block a pull request or push. The job writes a JSON report and uploads it as the `checkov-terraform-report` artifact, including when Checkov reports failed checks. Open the workflow run's **Artifacts** section to download it. The job summary lists each finding with the severity reported by Checkov (or `Unclassified` when Checkov provides none), Checkov check ID, Terraform resource address, and file location.

Run the scan locally from the repository root:

```sh
python -m pip install checkov==3.4.0
checkov --directory airbnb-infra-spoof --framework terraform
checkov --directory airbnb-infra-spoof --framework terraform --output json --output-file-path checkov-report
```

Checkov reports policy checks, failed resources, check IDs, and source locations; inspect the associated Terraform before deciding whether a result is a vulnerability, a policy gap, or an intentional design choice. The open-source report may not assign a normalized severity to every result, so the workflow marks missing severity as `Unclassified` rather than guessing. Review known demo-specific exceptions by their exact check IDs, and keep the explanation here specific and current. Do not suppress checks broadly or mark an issue intentional solely to make the count lower.

The initial baseline contained 82 failed checks and 126 passed checks (Checkov 3.4.0). This change fixes actionable gaps in egress rules, default security-group rules, public-subnet public-IP assignment, KMS encryption for S3, CloudWatch logs, RDS Performance Insights, and Redis, S3 versioning, security-group rule descriptions, and the Lambda's API Gateway resource scope. The scan remains report-only so the remaining baseline can be reviewed before introducing a blocking gate.

### Known intentional demo exceptions

- `CKV_AWS_260`: the internet-facing ALB accepts public HTTP on port 80 because this sample has no DNS name or ACM certificate configured. This is not production-safe for authenticated or sensitive traffic.
- `CKV_AWS_2`, `CKV_AWS_103`, and `CKV2_AWS_20`: the ALB has no HTTPS listener or HTTP-to-HTTPS redirect for the same missing-certificate reason. Configure ACM/TLS and redirect before production.
- `CKV_AWS_378`: the ALB forwards HTTP to targets in private application subnets; the target groups are not directly internet-facing. Configure TLS to targets if the threat model requires encryption inside the VPC.
- `CKV_AWS_309`: the sample API Gateway WebSocket routes have no authorization configured; the checked-in Lambda is a placeholder handler and the example has no identity/authentication design. Add route authorization before exposing real user data or actions.
- `CKV_AWS_338`: the ECS log group retains logs for 30 days to limit cost in the disposable dev environment; production retention must follow audit requirements.
- `CKV_AWS_150` and `CKV_AWS_293`: load balancer and RDS deletion protection are disabled for easy teardown of this dev example. Enable them for persistent environments.
- `CKV_AWS_157`: the single-AZ, small RDS instance is a cost choice for dev, not a production availability recommendation.
- `CKV2_AWS_42`: the CloudFront default certificate is used with the default CloudFront domain; there is no custom hostname configured.
- `CKV_AWS_374`: media is intended to be globally available, so the CloudFront distribution has no geographic restriction.
- `CKV_AWS_305`: the CloudFront distribution serves media objects rather than a website, so it has no default root object.
- `CKV2_AWS_5`: Checkov's graph check does not follow the security-group IDs across the module outputs and inputs. The dev root module passes the ALB, ECS, database, Redis, OpenSearch, and Lambda groups to their respective resources; verify those attachments in `airbnb-infra-spoof/environments/dev/main.tf` and the module resources.
Other Checkov findings remain visible in the report and are not treated as intentional exceptions without review. Public CloudFront media distribution, missing WAF/access logging, database operational controls, and other remaining findings need project-specific decisions before promoting the scan to a blocking gate.

Checkov complements the existing Terraform formatting and validation jobs: it evaluates security policies in configuration, while `terraform fmt` checks formatting and `terraform validate` checks configuration syntax and internal consistency. It does not require AWS credentials, contact a live account, or replace a plan review.
