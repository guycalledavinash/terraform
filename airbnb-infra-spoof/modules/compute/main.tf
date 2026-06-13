locals {
  common_tags = merge(var.tags, { Project = var.name, Environment = var.environment, Layer = "compute" })
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.name}-${var.environment}"
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name}-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = local.common_tags
}

resource "aws_lb" "this" {
  name               = "${var.name}-${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]
  tags               = local.common_tags
}

resource "aws_lb_target_group" "api" {
  name        = "${var.name}-${var.environment}-api"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path    = "/health"
    matcher = "200-399"
  }
  tags = local.common_tags
}

resource "aws_lb_target_group" "web" {
  name        = "${var.name}-${var.environment}-web"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path    = "/"
    matcher = "200-399"
  }
  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name = "${var.name}-${var.environment}-ecs-execution"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }] })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.name}-${var.environment}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{ name = "api", image = var.api_image, essential = true, portMappings = [{ containerPort = 8080, protocol = "tcp" }], environment = [{ name = "DATABASE_HOST", value = var.database_endpoint }, { name = "REDIS_HOST", value = var.redis_endpoint }, { name = "OPENSEARCH_ENDPOINT", value = var.opensearch_endpoint }, { name = "MEDIA_BUCKET", value = var.media_bucket_name }], logConfiguration = { logDriver = "awslogs", options = { awslogs-group = aws_cloudwatch_log_group.ecs.name, awslogs-region = data.aws_region.current.name, awslogs-stream-prefix = "api" } } }])
  tags = local.common_tags
}

resource "aws_ecs_task_definition" "web" {
  family                   = "${var.name}-${var.environment}-web"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{ name = "web", image = var.web_image, essential = true, portMappings = [{ containerPort = 3000, protocol = "tcp" }], environment = [{ name = "API_BASE_URL", value = "/api" }], logConfiguration = { logDriver = "awslogs", options = { awslogs-group = aws_cloudwatch_log_group.ecs.name, awslogs-region = data.aws_region.current.name, awslogs-stream-prefix = "web" } } }])
  tags = local.common_tags
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8080
  }
  depends_on = [aws_lb_listener.http]
  tags       = local.common_tags
}

resource "aws_ecs_service" "web" {
  name            = "web"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 3000
  }
  depends_on = [aws_lb_listener.http]
  tags       = local.common_tags
}

data "aws_region" "current" {}
