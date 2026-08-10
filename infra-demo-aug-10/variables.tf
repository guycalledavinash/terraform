variable "aws_region" { description = "AWS region." type = string default = "us-east-1" }
variable "project_name" { description = "Name prefix for all resources." type = string default = "infra-demo-aug-10" }
variable "environment" { description = "Environment name." type = string default = "demo" }
variable "vpc_cidr" { description = "VPC CIDR block." type = string default = "10.10.0.0/16" }
variable "allowed_http_cidr_blocks" { description = "CIDR ranges allowed to reach the public ALB." type = list(string) default = ["0.0.0.0/0"] }
variable "instance_type" { description = "EC2 instance type for web and app tiers." type = string default = "t3.micro" }
variable "web_desired_capacity" { description = "Desired web tier instances." type = number default = 2 }
variable "app_desired_capacity" { description = "Desired app tier instances." type = number default = 2 }
variable "database_name" { description = "Initial MySQL database name." type = string default = "webappdb" }
variable "database_username" { description = "RDS master username." type = string default = "adminuser" }
variable "database_instance_class" { description = "RDS instance class." type = string default = "db.t4g.micro" }
variable "database_allocated_storage" { description = "Allocated RDS storage in GiB." type = number default = 20 }
variable "enable_deletion_protection" { description = "Enable RDS deletion protection." type = bool default = true }
variable "app_artifact_bucket_name" { description = "Optional globally unique bucket name for deployment artifacts. Leave null to generate one." type = string default = null }
