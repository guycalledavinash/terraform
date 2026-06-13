variable "name" { type = string }
variable "environment" { type = string }
variable "private_app_subnet_ids" { type = list(string) }
variable "lambda_security_group_id" { type = string }
variable "kms_key_arn" { type = string }
variable "lambda_package_path" { type = string }
variable "tags" { type = map(string) default = {} }
