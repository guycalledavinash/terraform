locals {
  name_prefix = "${var.project_name}-${var.environment}"
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "guycalledavinash/terraform"
    Workload    = "aws-three-tier-web-app"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_password" "database" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "random_id" "bucket" {
  byte_length = 4
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

resource "aws_subnet" "public" {
  for_each                = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, i) }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = { Name = "${local.name_prefix}-public-${each.key}", Tier = "public" }
}

resource "aws_subnet" "web" {
  for_each          = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, i + 10) }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = { Name = "${local.name_prefix}-web-${each.key}", Tier = "web" }
}

resource "aws_subnet" "app" {
  for_each          = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, i + 20) }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = { Name = "${local.name_prefix}-app-${each.key}", Tier = "application" }
}

resource "aws_subnet" "database" {
  for_each          = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, i + 30) }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = { Name = "${local.name_prefix}-db-${each.key}", Tier = "database" }
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = { Name = "${local.name_prefix}-nat-${each.key}" }
}

resource "aws_nat_gateway" "main" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags          = { Name = "${local.name_prefix}-nat-${each.key}" }
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.main
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = each.value.id
  }
  tags = { Name = "${local.name_prefix}-private-${each.key}-rt" }
}

resource "aws_route_table_association" "web" {
  for_each       = aws_subnet.web
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
resource "aws_route_table_association" "database" {
  for_each       = aws_subnet.database
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_security_group" "public_alb" {
  name        = "${local.name_prefix}-public-alb-sg"
  description = "HTTP ingress for the public web load balancer"
  vpc_id      = aws_vpc.main.id
  ingress { from_port = 80 to_port = 80 protocol = "tcp" cidr_blocks = var.allowed_http_cidr_blocks }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Only public ALB can reach web tier"
  vpc_id      = aws_vpc.main.id
  ingress { from_port = 80 to_port = 80 protocol = "tcp" security_groups = [aws_security_group.public_alb.id] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "internal_alb" {
  name        = "${local.name_prefix}-internal-alb-sg"
  description = "Web tier to private app load balancer"
  vpc_id      = aws_vpc.main.id
  ingress { from_port = 80 to_port = 80 protocol = "tcp" security_groups = [aws_security_group.web.id] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Only internal ALB can reach app tier"
  vpc_id      = aws_vpc.main.id
  ingress { from_port = 4000 to_port = 4000 protocol = "tcp" security_groups = [aws_security_group.internal_alb.id] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-db-sg"
  description = "Only app tier can reach MySQL"
  vpc_id      = aws_vpc.main.id
  ingress { from_port = 3306 to_port = 3306 protocol = "tcp" security_groups = [aws_security_group.app.id] }
}

resource "aws_s3_bucket" "artifacts" { bucket = coalesce(var.app_artifact_bucket_name, "${local.name_prefix}-artifacts-${random_id.bucket.hex}") }
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = values(aws_subnet.database)[*].id
}
resource "aws_db_instance" "main" {
  identifier                 = "${local.name_prefix}-mysql"
  engine                     = "mysql"
  engine_version             = "8.0"
  instance_class             = var.database_instance_class
  allocated_storage          = var.database_allocated_storage
  db_name                    = var.database_name
  username                   = var.database_username
  password                   = random_password.database.result
  db_subnet_group_name       = aws_db_subnet_group.main.name
  vpc_security_group_ids     = [aws_security_group.database.id]
  multi_az                   = true
  storage_encrypted          = true
  backup_retention_period    = 7
  deletion_protection        = var.enable_deletion_protection
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${local.name_prefix}-final"
  auto_minor_version_upgrade = true
}
