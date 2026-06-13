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
  description = "Internet traffic to Airbnb-like ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-alb-sg" })
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-${var.environment}-ecs"
  description = "ECS service traffic from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-ecs-sg" })
}

resource "aws_security_group" "database" {
  name        = "${var.name}-${var.environment}-database"
  description = "Database access from application tier"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.ecs.id, aws_security_group.lambda.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-database-sg" })
}

resource "aws_security_group" "redis" {
  name        = "${var.name}-${var.environment}-redis"
  description = "Redis access from services and real-time Lambda"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = [aws_security_group.ecs.id, aws_security_group.lambda.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-redis-sg" })
}

resource "aws_security_group" "opensearch" {
  name        = "${var.name}-${var.environment}-opensearch"
  description = "OpenSearch access from application tier"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-opensearch-sg" })
}

resource "aws_security_group" "lambda" {
  name        = "${var.name}-${var.environment}-lambda"
  description = "Real-time Lambda outbound access"
  vpc_id      = var.vpc_id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.name}-${var.environment}-lambda-sg" })
}
