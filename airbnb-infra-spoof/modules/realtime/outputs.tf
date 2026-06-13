output "websocket_url" { value = aws_apigatewayv2_stage.this.invoke_url }
output "connections_table_name" { value = aws_dynamodb_table.connections.name }
output "booking_events_topic_arn" { value = aws_sns_topic.booking_events.arn }
