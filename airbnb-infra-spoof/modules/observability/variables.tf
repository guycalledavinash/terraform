variable "name" { type = string }
variable "environment" { type = string }
variable "alb_name" { type = string }
variable "api_target_group_arn" { type = string }
variable "tags" { type = map(string) default = {} }
