# Airbnb-like real-time AWS infrastructure

This Terraform project provisions a production-style, real-time platform for a marketplace application similar to Airbnb. It is intentionally modular so teams can evolve the networking, compute, data, real-time, and observability layers independently.

## Architecture

The stack creates:

- A multi-AZ VPC with public, private application, and private database subnets.
- NAT gateways and route tables for private outbound traffic.
- Security groups for an internet-facing ALB, ECS services, RDS PostgreSQL, ElastiCache Redis, OpenSearch, Lambda, and VPC endpoints.
- ECS Fargate services behind an Application Load Balancer for the API and web application containers.
- PostgreSQL on Amazon RDS for bookings, users, listings, and payments metadata.
- ElastiCache Redis for low-latency sessions, availability locks, rate limiting, and ephemeral state.
- OpenSearch for location/listing search.
- S3 and CloudFront for listing images and other static media.
- API Gateway WebSocket API, Lambda, DynamoDB connection registry, and SNS topics for real-time booking, chat, and notification fan-out.
- CloudWatch dashboards, alarms, log groups, and synthetic-style health metrics hooks.

## Suggested layout

```text
airbnb-infra-spoof/
├── environments/dev/        # Example dev environment wiring all modules together
└── modules/
    ├── compute/             # ALB, ECS cluster, task definitions, services, autoscaling
    ├── data/                # RDS, Redis, OpenSearch, media bucket, CloudFront
    ├── networking/          # VPC, subnets, NAT, routes, endpoints
    ├── observability/       # Logs, dashboard, alarms
    ├── realtime/            # WebSocket API, Lambda, DynamoDB, SNS
    └── security/            # Security groups and KMS keys
```

## Deploy

1. Configure AWS credentials for the target account.
2. Copy `environments/dev/terraform.tfvars.example` to `environments/dev/terraform.tfvars` and adjust values.
3. Run:

```bash
cd airbnb-infra-spoof/environments/dev
terraform init
terraform plan
terraform apply
```

## Notes

- Defaults favor a realistic non-production deployment. Increase instance sizes, shard counts, and desired task counts for production.
- The WebSocket Lambda package path is configurable so application teams can provide their own handler artifact.
- Secrets should be supplied through variables, CI secret stores, or AWS Secrets Manager rather than committed to source control.
