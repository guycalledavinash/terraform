variable "aws_region" {
  description = "AWS region for the GoalHub FIFA infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to prefix resources."
  type        = string
  default     = "goalhub-fifa"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "season"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "frontend_image" {
  description = "Container image for the React/Vite GoalHub frontend."
  type        = string
  default     = "nginx:1.27-alpine"
}

variable "backend_image" {
  description = "Container image for the FastAPI GoalHub backend."
  type        = string
  default     = "public.ecr.aws/docker/library/python:3.12-slim"
}

variable "frontend_desired_count" {
  description = "Desired number of frontend ECS tasks."
  type        = number
  default     = 2
}

variable "backend_desired_count" {
  description = "Desired number of backend ECS tasks."
  type        = number
  default     = 2
}

variable "database_name" {
  description = "PostgreSQL database name for GoalHub."
  type        = string
  default     = "goalhub"
}

variable "database_username" {
  description = "PostgreSQL admin username."
  type        = string
  default     = "goalhub_admin"
}

variable "database_password" {
  description = "PostgreSQL admin password. Override with TF_VAR_database_password."
  type        = string
  sensitive   = true
  default     = "ChangeMeGoalHub2026!"
}

variable "jwt_secret" {
  description = "JWT signing secret stored in Secrets Manager for the FastAPI service. Override in real deployments."
  type        = string
  sensitive   = true
  default     = "replace-this-fifa-season-jwt-secret"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
