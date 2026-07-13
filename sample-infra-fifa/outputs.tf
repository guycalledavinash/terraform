output "alb_dns_name" {
  description = "Public URL for GoalHub frontend and API path routing."
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster running the GoalHub services."
  value       = aws_ecs_cluster.main.name
}

output "database_endpoint" {
  description = "Private PostgreSQL endpoint for GoalHub."
  value       = aws_db_instance.postgres.address
}

output "media_cdn_domain_name" {
  description = "CloudFront domain for FIFA team/player media."
  value       = aws_cloudfront_distribution.media.domain_name
}
