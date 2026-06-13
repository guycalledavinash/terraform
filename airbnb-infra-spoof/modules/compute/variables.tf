variable "name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_app_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "ecs_security_group_id" { type = string }
variable "api_image" { type = string }
variable "web_image" { type = string }
variable "database_endpoint" { type = string }
variable "redis_endpoint" { type = string }
variable "opensearch_endpoint" { type = string }
variable "media_bucket_name" { type = string }
variable "desired_count" {
  type = number
  default = 2
}
variable "tags" { type = map(string) default = {} }
