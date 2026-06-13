output "application_url" { value = "http://${module.compute.alb_dns_name}" }
output "websocket_url" { value = module.realtime.websocket_url }
output "media_cdn_domain_name" { value = module.data.media_cdn_domain_name }
output "database_endpoint" { value = module.data.database_endpoint }
