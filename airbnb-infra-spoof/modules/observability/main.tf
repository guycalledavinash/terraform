locals { common_tags = merge(var.tags, { Project = var.name, Environment = var.environment, Layer = "observability" }) }

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-${var.environment}-operations"
  dashboard_body = jsonencode({ widgets = [{ type = "metric", width = 12, height = 6, properties = { metrics = [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_name]], period = 60, stat = "Sum", region = data.aws_region.current.name, title = "ALB target 5XX" } }] })
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.name}-${var.environment}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "High 5XX count from Airbnb-like API target group"
  dimensions          = { TargetGroup = trimprefix(var.api_target_group_arn, "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:targetgroup/") }
  treat_missing_data  = "notBreaching"
  tags                = local.common_tags
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
