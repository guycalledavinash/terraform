variable "aws_region" {
  type = string
  default = "us-east-1"
}
variable "name" {
  type = string
  default = "airbnb-infra-spoof"
}
variable "environment" {
  type = string
  default = "dev"
}
variable "vpc_cidr" {
  type = string
  default = "10.42.0.0/16"
}
variable "availability_zones" {
  type = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
variable "api_image" {
  type = string
  default = "public.ecr.aws/nginx/nginx:latest"
}
variable "web_image" {
  type = string
  default = "public.ecr.aws/nginx/nginx:latest"
}
variable "db_username" {
  type = string
  default = "airbnb_app"
}
variable "db_password" {
  type = string
  sensitive = true
}
