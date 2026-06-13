locals {
  common_tags = merge(var.tags, {
    Project     = var.name
    Environment = var.environment
    Layer       = "data"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-${var.environment}-db"
  subnet_ids = var.private_db_subnet_ids
  tags       = local.common_tags
}

resource "aws_db_instance" "postgres" {
  identifier                 = "${var.name}-${var.environment}-postgres"
  engine                     = "postgres"
  engine_version             = "16.3"
  instance_class             = var.db_instance_class
  allocated_storage          = 50
  max_allocated_storage      = 500
  storage_encrypted          = true
  kms_key_id                 = var.kms_key_arn
  db_name                    = "airbnb"
  username                   = var.db_username
  password                   = var.db_password
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [var.database_security_group_id]
  backup_retention_period    = 7
  deletion_protection        = false
  skip_final_snapshot        = true
  performance_insights_enabled = true
  tags                       = local.common_tags
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-${var.environment}-redis"
  subnet_ids = var.private_app_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name}-${var.environment}-redis"
  description                = "Redis for sessions, rate limiting, availability locks, and real-time ephemeral state"
  engine                     = "redis"
  node_type                  = var.redis_node_type
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [var.redis_security_group_id]
  tags                       = local.common_tags
}

resource "aws_opensearch_domain" "search" {
  domain_name    = "${var.name}-${var.environment}-search"
  engine_version = "OpenSearch_2.13"

  cluster_config {
    instance_type  = var.opensearch_instance_type
    instance_count = 2
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  vpc_options {
    subnet_ids         = slice(var.private_app_subnet_ids, 0, 2)
    security_group_ids = [var.opensearch_security_group_id]
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_arn
  }
  node_to_node_encryption {
    enabled = true
  }
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }
  ebs_options {
    ebs_enabled = true
    volume_size = 20
    volume_type = "gp3"
  }
  tags = local.common_tags
}

resource "aws_s3_bucket" "media" {
  bucket_prefix = "${var.name}-${var.environment}-media-"
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "media" {
  name                              = "${var.name}-${var.environment}-media-oac"
  description                       = "Restrict media bucket access to CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "media" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Media CDN for ${var.name} ${var.environment}"

  origin {
    domain_name              = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id                = "media-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.media.id
  }

  default_cache_behavior {
    target_origin_id       = "media-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  tags = local.common_tags
}
