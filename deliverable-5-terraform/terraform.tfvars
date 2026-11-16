# =====================
# PaySecure DR Values
# Fill these before running terraform apply
# =====================

project_name   = "paysecure"
environment    = "production"
domain_name    = "api.paysecure.in"
hosted_zone_id = "YOUR_HOSTED_ZONE_ID"

# Database
db_name               = "paysecure"
db_username           = "paysecure_admin"
aurora_instance_class = "db.r6g.large"

# Cache
redis_node_type = "cache.r6g.large"

# Container Images
payment_service_image    = "YOUR_ECR_REPO/payment-service:latest"
auth_service_image       = "YOUR_ECR_REPO/auth-service:latest"
settlement_service_image = "YOUR_ECR_REPO/settlement-service:latest"