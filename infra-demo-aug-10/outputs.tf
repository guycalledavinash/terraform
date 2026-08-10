output "public_alb_dns_name" { description = "Public web entry point." value = aws_lb.public.dns_name }
output "internal_alb_dns_name" { description = "Private application load balancer DNS name." value = aws_lb.internal.dns_name }
output "artifact_bucket_name" { description = "Private S3 bucket for application build artifacts." value = aws_s3_bucket.artifacts.bucket }
output "database_endpoint" { description = "RDS endpoint for the application tier." value = aws_db_instance.main.endpoint sensitive = true }
