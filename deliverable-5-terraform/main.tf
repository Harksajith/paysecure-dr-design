# PaySecure DR Infrastructure
# Main Terraform Configuration
# Manages: Mumbai (Primary) + Hyderabad (Secondary) regions

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "paysecure-terraform-state"
    key            = "dr/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "paysecure-terraform-locks"
  }
}

# Mumbai Provider (Primary)
provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "PaySecure-DR"
      Environment = "Production"
      ManagedBy   = "Terraform"
      Region      = "Primary-Mumbai"
    }
  }
}

# Hyderabad Provider (Secondary)
provider "aws" {
  alias  = "hyderabad"
  region = "ap-south-2"

  default_tags {
    tags = {
      Project     = "PaySecure-DR"
      Environment = "Production"
      ManagedBy   = "Terraform"
      Region      = "Secondary-Hyderabad"
    }
  }
}

# Global provider for Route53 and IAM
provider "aws" {
  alias  = "global"
  region = "us-east-1"
}

# =====================
# Aurora Global Database
# =====================
module "aurora" {
  source = "./modules/aurora"

  providers = {
    aws.mumbai    = aws.mumbai
    aws.hyderabad = aws.hyderabad
  }

  project_name        = var.project_name
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  mumbai_subnet_ids   = module.vpc_mumbai.private_subnet_ids
  hyderabad_subnet_ids = module.vpc_hyderabad.private_subnet_ids
  mumbai_vpc_id       = module.vpc_mumbai.vpc_id
  hyderabad_vpc_id    = module.vpc_hyderabad.vpc_id
  instance_class      = var.aurora_instance_class
}

# =====================
# DynamoDB Global Tables
# =====================
module "dynamodb" {
  source = "./modules/dynamodb"

  providers = {
    aws.mumbai    = aws.mumbai
    aws.hyderabad = aws.hyderabad
  }

  project_name = var.project_name
}

# =====================
# ElastiCache Redis
# =====================
module "elasticache" {
  source = "./modules/elasticache"

  providers = {
    aws.mumbai    = aws.mumbai
    aws.hyderabad = aws.hyderabad
  }

  project_name         = var.project_name
  mumbai_subnet_ids    = module.vpc_mumbai.private_subnet_ids
  hyderabad_subnet_ids = module.vpc_hyderabad.private_subnet_ids
  mumbai_vpc_id        = module.vpc_mumbai.vpc_id
  hyderabad_vpc_id     = module.vpc_hyderabad.vpc_id
  node_type            = var.redis_node_type
}

# =====================
# ECS Fargate Services
# =====================
module "ecs" {
  source = "./modules/ecs"

  providers = {
    aws.mumbai    = aws.mumbai
    aws.hyderabad = aws.hyderabad
  }

  project_name              = var.project_name
  mumbai_subnet_ids         = module.vpc_mumbai.private_subnet_ids
  hyderabad_subnet_ids      = module.vpc_hyderabad.private_subnet_ids
  mumbai_vpc_id             = module.vpc_mumbai.vpc_id
  hyderabad_vpc_id          = module.vpc_hyderabad.vpc_id
  mumbai_alb_arn            = module.vpc_mumbai.alb_arn
  hyderabad_alb_arn         = module.vpc_hyderabad.alb_arn
  payment_service_image     = var.payment_service_image
  auth_service_image        = var.auth_service_image
  settlement_service_image  = var.settlement_service_image
}

# =====================
# Route53 DNS Failover
# =====================
module "route53" {
  source = "./modules/route53"

  providers = {
    aws = aws.global
  }

  domain_name          = var.domain_name
  hosted_zone_id       = var.hosted_zone_id
  mumbai_alb_dns       = module.vpc_mumbai.alb_dns_name
  mumbai_alb_zone_id   = module.vpc_mumbai.alb_zone_id
  hyderabad_alb_dns    = module.vpc_hyderabad.alb_dns_name
  hyderabad_alb_zone_id = module.vpc_hyderabad.alb_zone_id
}