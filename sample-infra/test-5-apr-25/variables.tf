variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^(us|ca|eu|ap|sa|af|me)-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region format like us-east-1."
  }
}

variable "project_name" {
  description = "Project name prefix used for resource naming and tags"
  type        = string
  default     = "policy-reporter-rt"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-30 chars, lowercase alphanumeric with internal hyphens only."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "AZs to use for high availability"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "availability_zones must include at least two AZs for high availability."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs aligned to availability_zones"
  type        = list(string)
  default     = ["10.42.1.0/24", "10.42.2.0/24"]

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every public_subnet_cidrs entry must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs aligned to availability_zones"
  type        = list(string)
  default     = ["10.42.11.0/24", "10.42.12.0/24"]

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every private_subnet_cidrs entry must be a valid IPv4 CIDR block."
  }
}

variable "container_image" {
  description = "Container image for policy reporter like workload"
  type        = string
  default     = "ghcr.io/kyverno/policy-reporter:latest"

  validation {
    condition     = length(trimspace(var.container_image)) > 0
    error_message = "container_image cannot be empty."
  }
}

variable "app_port" {
  description = "Application port exposed by container"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "cpu" {
  description = "Task CPU units"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be one of the common ECS Fargate values: 256, 512, 1024, 2048, 4096."
  }
}

variable "memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 512

  validation {
    condition     = var.memory >= 512
    error_message = "memory must be at least 512 MiB for ECS Fargate workloads."
  }
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count must be at least 1."
  }
}

variable "min_capacity" {
  description = "Minimum autoscaling capacity"
  type        = number
  default     = 2

  validation {
    condition     = var.min_capacity >= 1
    error_message = "min_capacity must be at least 1."
  }
}

variable "max_capacity" {
  description = "Maximum autoscaling capacity"
  type        = number
  default     = 6

  validation {
    condition     = var.max_capacity >= 1
    error_message = "max_capacity must be at least 1."
  }
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:acm:[a-z0-9-]+:[0-9]{12}:certificate/.+$", var.acm_certificate_arn))
    error_message = "acm_certificate_arn must be a valid ACM certificate ARN."
  }
}
