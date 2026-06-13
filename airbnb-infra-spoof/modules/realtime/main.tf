locals { common_tags = merge(var.tags, { Project = var.name, Environment = var.environment, Layer = "realtime" }) }

resource "aws_dynamodb_table" "connections" {
  name         = "${var.name}-${var.environment}-websocket-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connection_id"
  attribute {
    name = "connection_id"
    type = "S"
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }
  tags = local.common_tags
}

resource "aws_sns_topic" "booking_events" {
  name              = "${var.name}-${var.environment}-booking-events"
  kms_master_key_id = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_iam_role" "lambda" {
  name = "${var.name}-${var.environment}-realtime-lambda"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }] })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "realtime" {
  name = "${var.name}-${var.environment}-realtime"
  role = aws_iam_role.lambda.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:UpdateItem"], Resource = aws_dynamodb_table.connections.arn }, { Effect = "Allow", Action = ["sns:Publish"], Resource = aws_sns_topic.booking_events.arn }, { Effect = "Allow", Action = ["execute-api:ManageConnections"], Resource = "*" }] })
}

resource "aws_lambda_function" "websocket" {
  function_name    = "${var.name}-${var.environment}-websocket-handler"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)
  timeout          = 15
  memory_size      = 256
  kms_key_arn      = var.kms_key_arn
  vpc_config {
    subnet_ids         = var.private_app_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }
  environment {
    variables = {
      CONNECTIONS_TABLE       = aws_dynamodb_table.connections.name
      BOOKING_EVENTS_TOPIC_ARN = aws_sns_topic.booking_events.arn
    }
  }
  tags = local.common_tags
}

resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${var.name}-${var.environment}-realtime"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  tags                       = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.websocket.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.websocket.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "routes" {
  for_each  = toset(["$connect", "$disconnect", "$default", "bookingUpdated", "chatMessage"])
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = var.environment
  auto_deploy = true
  tags        = local.common_tags
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}
