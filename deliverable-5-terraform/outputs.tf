# =====================
# Output Values
# =====================

output "mumbai_aurora_endpoint" {
  description = "Aurora writer endpoint in Mumbai"
  value       = module.aurora.mumbai_writer_endpoint
  sensitive   = true
}

output "hyderabad_aurora_endpoint" {
  description = "Aurora writer endpoint in Hyderabad (after failover)"
  value       = module.aurora.hyderabad_writer_endpoint
  sensitive   = true
}

output "mumbai_redis_endpoint" {
  description = "Redis primary endpoint in Mumbai"
  value       = module.elasticache.mumbai_primary_endpoint
  sensitive   = true
}

output "hyderabad_redis_endpoint" {
  description = "Redis primary endpoint in Hyderabad"
  value       = module.elasticache.hyderabad_primary_endpoint
  sensitive   = true
}

output "mumbai_alb_dns" {
  description = "Mumbai ALB DNS name"
  value       = module.vpc_mumbai.alb_dns_name
}

output "hyderabad_alb_dns" {
  description = "Hyderabad ALB DNS name"
  value       = module.vpc_hyderabad.alb_dns_name
}

output "api_endpoint" {
  description = "Main API endpoint (Route53)"
  value       = "https://${var.domain_name}"
}

output "route53_health_check_id" {
  description = "Route53 health check ID for Mumbai"
  value       = module.route53.mumbai_health_check_id
}