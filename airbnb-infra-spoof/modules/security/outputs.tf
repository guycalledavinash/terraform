output "kms_key_arn" { value = aws_kms_key.app.arn }
output "alb_security_group_id" { value = aws_security_group.alb.id }
output "ecs_security_group_id" { value = aws_security_group.ecs.id }
output "database_security_group_id" { value = aws_security_group.database.id }
output "redis_security_group_id" { value = aws_security_group.redis.id }
output "opensearch_security_group_id" { value = aws_security_group.opensearch.id }
output "lambda_security_group_id" { value = aws_security_group.lambda.id }
