variable "name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_db_subnet_ids" { type = list(string) }
variable "private_app_subnet_ids" { type = list(string) }
variable "database_security_group_id" { type = string }
variable "redis_security_group_id" { type = string }
variable "opensearch_security_group_id" { type = string }
variable "kms_key_arn" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type = string
  sensitive = true
}
variable "db_instance_class" {
  type = string
  default = "db.t4g.micro"
}
variable "redis_node_type" {
  type = string
  default = "cache.t4g.micro"
}
variable "opensearch_instance_type" {
  type = string
  default = "t3.small.search"
}
variable "tags" { type = map(string) default = {} }
