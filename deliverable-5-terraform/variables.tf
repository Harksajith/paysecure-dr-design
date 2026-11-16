# =====================
# Project Variables
# =====================

variable "project_name" {
  description = "Project name used for all resource naming"
  type        = string
  default     = "paysecure"
}

variable "domain_name" {
  description = "Main domain name for PaySecure API"
  type        = string
  default     = "api.paysecure.in"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

# =====================
# Database Variables
# =====================

variable "db_name" {
  description = "Aurora PostgreSQL database name"
  type        = string
  default     = "paysecure"
}

variable "db_username" {
  description = "Aurora master username"
  type        = string
  default     = "paysecure_admin"
  sensitive   = true
}

variable "db_password" {
  description = "Aurora master password"
  type        = string
  sensitive   = true
}

variable "aurora_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.r6g.large"
}

# =====================
# Cache Variables
# =====================

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.r6g.large"
}

# =====================
# Container Variables
# =====================

variable "payment_service_image" {
  description = "Docker image for payment service"
  type        = string
}

variable "auth_service_image" {
  description = "Docker image for auth service"
  type        = string
}

variable "settlement_service_image" {
  description = "Docker image for settlement service"
  type        = string
}

# =====================
# Environment Variables
# =====================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging or development."
  }
}