variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix used for resource naming and tags"
  type        = string
  default     = "policy-reporter-rt"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.42.0.0/16"
}

variable "availability_zones" {
  description = "AZs to use for high availability"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs aligned to availability_zones"
  type        = list(string)
  default     = ["10.42.1.0/24", "10.42.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs aligned to availability_zones"
  type        = list(string)
  default     = ["10.42.11.0/24", "10.42.12.0/24"]
}

variable "container_image" {
  description = "Container image for policy reporter like workload"
  type        = string
  default     = "ghcr.io/kyverno/policy-reporter:latest"
}

variable "app_port" {
  description = "Application port exposed by container"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum autoscaling capacity"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum autoscaling capacity"
  type        = number
  default     = 6
}
