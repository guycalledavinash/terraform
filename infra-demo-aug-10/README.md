# infra-demo-aug-10 AWS three-tier infrastructure

Terraform for a generic, secure AWS deployment shaped for [`iamtejasmane/aws-three-tier-web-app`](https://github.com/iamtejasmane/aws-three-tier-web-app). The stack follows the workshop-style three-tier pattern: public entry point, isolated web tier, isolated app tier, and private database tier.

## Architecture

- Multi-AZ VPC with public, web, application, and database subnets.
- Public Application Load Balancer accepts HTTP traffic and forwards only to private web instances.
- Internal Application Load Balancer accepts traffic only from the web tier and forwards to private app instances.
- Auto Scaling Groups for web and app tiers using Amazon Linux 2023 launch templates with IMDSv2 required.
- RDS MySQL in private database subnets with encryption, Multi-AZ, backups, random generated password, and deletion protection enabled by default.
- Private, encrypted, versioned S3 artifact bucket for application bundles.
- AWS Systems Manager instance profile for administration without opening SSH.

## Security defaults

- No public IPs on web, app, or database instances.
- No SSH ingress security-group rule; use Session Manager if access is needed.
- Database accepts MySQL only from the app tier security group.
- App tier accepts port `4000` only from the internal ALB.
- Web tier accepts port `80` only from the public ALB.
- Artifact bucket blocks all public access and enables server-side encryption.

## Deploy

```bash
cd infra-demo-aug-10
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

The included user data starts placeholder web and app services so the infrastructure can be tested before wiring the real application artifacts. Replace the user-data bootstrap with the build and runtime commands for the upstream app when you are ready to deploy application code.

> Cost note: this creates two NAT gateways, two load balancers, EC2 instances, and a Multi-AZ RDS database. Destroy demo environments when finished.
