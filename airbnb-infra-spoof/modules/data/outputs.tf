output "database_endpoint" { value = aws_db_instance.postgres.address }
output "redis_primary_endpoint" { value = aws_elasticache_replication_group.redis.primary_endpoint_address }
output "opensearch_endpoint" { value = aws_opensearch_domain.search.endpoint }
output "media_bucket_name" { value = aws_s3_bucket.media.id }
output "media_cdn_domain_name" { value = aws_cloudfront_distribution.media.domain_name }
