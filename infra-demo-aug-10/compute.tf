resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_lb" "public" {
  name               = "${local.name_prefix}-public"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb.id]
  subnets            = values(aws_subnet.public)[*].id
}
resource "aws_lb" "internal" {
  name               = "${local.name_prefix}-internal"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  subnets            = values(aws_subnet.app)[*].id
}

resource "aws_lb_target_group" "web" { name = "${local.name_prefix}-web" port = 80 protocol = "HTTP" vpc_id = aws_vpc.main.id health_check { path = "/" } }
resource "aws_lb_target_group" "app" { name = "${local.name_prefix}-app" port = 4000 protocol = "HTTP" vpc_id = aws_vpc.main.id health_check { path = "/health" matcher = "200-399" } }
resource "aws_lb_listener" "public_http" { load_balancer_arn = aws_lb.public.arn port = 80 protocol = "HTTP" default_action { type = "forward" target_group_arn = aws_lb_target_group.web.arn } }
resource "aws_lb_listener" "internal_http" { load_balancer_arn = aws_lb.internal.arn port = 80 protocol = "HTTP" default_action { type = "forward" target_group_arn = aws_lb_target_group.app.arn } }

resource "aws_launch_template" "web" {
  name_prefix            = "${local.name_prefix}-web-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  update_default_version = true
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }
  vpc_security_group_ids = [aws_security_group.web.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  user_data = base64encode(templatefile("${path.module}/user-data-web.sh", { app_url = "http://${aws_lb.internal.dns_name}" }))
}

resource "aws_launch_template" "app" {
  name_prefix            = "${local.name_prefix}-app-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  update_default_version = true
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }
  vpc_security_group_ids = [aws_security_group.app.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  user_data = base64encode(templatefile("${path.module}/user-data-app.sh", { db_host = aws_db_instance.main.address, db_name = var.database_name }))
}

resource "aws_autoscaling_group" "web" {
  name                = "${local.name_prefix}-web-asg"
  desired_capacity    = var.web_desired_capacity
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = values(aws_subnet.web)[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name_prefix}-app-asg"
  desired_capacity    = var.app_desired_capacity
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = values(aws_subnet.app)[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app"
    propagate_at_launch = true
  }
}
