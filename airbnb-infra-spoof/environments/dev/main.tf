locals {
  tags = {
    Application = "airbnb-infra-spoof"
    ManagedBy   = "terraform"
    Environment = var.environment
  }
}

data "archive_file" "websocket_handler" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/websocket-handler"
  output_path = "${path.module}/websocket-handler.zip"
}

module "networking" {
  source                   = "../../modules/networking"
  name                     = var.name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = ["10.42.0.0/24", "10.42.1.0/24"]
  private_app_subnet_cidrs = ["10.42.10.0/24", "10.42.11.0/24"]
  private_db_subnet_cidrs  = ["10.42.20.0/24", "10.42.21.0/24"]
  tags                     = local.tags
}

module "security" {
  source         = "../../modules/security"
  name           = var.name
  environment    = var.environment
  vpc_id         = module.networking.vpc_id
  vpc_cidr_block = module.networking.vpc_cidr_block
  tags           = local.tags
}

module "data" {
  source                       = "../../modules/data"
  name                         = var.name
  environment                  = var.environment
  vpc_id                       = module.networking.vpc_id
  private_db_subnet_ids        = module.networking.private_db_subnet_ids
  private_app_subnet_ids       = module.networking.private_app_subnet_ids
  database_security_group_id   = module.security.database_security_group_id
  redis_security_group_id      = module.security.redis_security_group_id
  opensearch_security_group_id = module.security.opensearch_security_group_id
  kms_key_arn                  = module.security.kms_key_arn
  db_username                  = var.db_username
  db_password                  = var.db_password
  tags                         = local.tags
}

module "compute" {
  source                = "../../modules/compute"
  name                  = var.name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  ecs_security_group_id = module.security.ecs_security_group_id
  api_image             = var.api_image
  web_image             = var.web_image
  database_endpoint     = module.data.database_endpoint
  redis_endpoint        = module.data.redis_primary_endpoint
  opensearch_endpoint   = module.data.opensearch_endpoint
  media_bucket_name     = module.data.media_bucket_name
  tags                  = local.tags
}

module "realtime" {
  source                   = "../../modules/realtime"
  name                     = var.name
  environment              = var.environment
  private_app_subnet_ids   = module.networking.private_app_subnet_ids
  lambda_security_group_id = module.security.lambda_security_group_id
  kms_key_arn              = module.security.kms_key_arn
  lambda_package_path      = data.archive_file.websocket_handler.output_path
  tags                     = local.tags
}

module "observability" {
  source               = "../../modules/observability"
  name                 = var.name
  environment          = var.environment
  alb_name             = module.compute.alb_dns_name
  api_target_group_arn = module.compute.api_target_group_arn
  tags                 = local.tags
}
