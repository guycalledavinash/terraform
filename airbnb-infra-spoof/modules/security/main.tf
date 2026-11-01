locals {
  common_tags = merge(var.tags, {
    Project     = var.name
    Environment = var.environment
    Layer       = "security"
  })
}

resource "aws_kms_key" "app" {
  description             = "KMS key for ${var.name} ${var.environment} application data"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "app" {
  name          = "alias/${var.name}-${var.environment}"
  target_key_id = aws_kms_key.app.key_id
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-${var.environment}-alb"
  description = "Internet traffic to the public application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Public HTTP entry point for the example web application"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Forward web traffic to application targets inside the VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    description = "Forward API traffic to application targets inside the VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-alb-sg" })
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-${var.environment}-ecs"
  description = "ECS service traffic from the load balancer and required dependencies"
  vpc_id      = var.vpc_id

  ingress {
    description     = "API traffic from the application load balancer"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description     = "Web traffic from the application load balancer"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    description = "PostgreSQL access inside the VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    description = "Redis access inside the VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    description = "OpenSearch and other VPC HTTPS dependencies"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    description = "HTTPS access to external APIs and AWS service endpoints through NAT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-ecs-sg" })
}

resource "aws_security_group" "database" {
  name        = "${var.name}-${var.environment}-database"
  description = "PostgreSQL access from the application tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access from ECS services"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-database-sg" })
}

resource "aws_security_group" "redis" {
  name        = "${var.name}-${var.environment}-redis"
  description = "Redis access from ECS services and real-time Lambda"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis access from the application and real-time Lambda"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id, aws_security_group.lambda.id]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-redis-sg" })
}

resource "aws_security_group" "opensearch" {
  name        = "${var.name}-${var.environment}-opensearch"
  description = "OpenSearch access from the application tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS access from ECS services"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-opensearch-sg" })
}

resource "aws_security_group" "lambda" {
  name        = "${var.name}-${var.environment}-lambda"
  description = "Real-time Lambda outbound HTTPS and Redis access"
  vpc_id      = var.vpc_id

  egress {
    description = "Redis access inside the VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    description = "HTTPS access to API Gateway and AWS service endpoints through NAT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-lambda-sg" })
}
