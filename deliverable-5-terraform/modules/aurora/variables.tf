variable "project_name" {
  description = "Project name"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "mumbai_subnet_ids" {
  description = "Private subnet IDs in Mumbai"
  type        = list(string)
}

variable "hyderabad_subnet_ids" {
  description = "Private subnet IDs in Hyderabad"
  type        = list(string)
}

variable "mumbai_vpc_id" {
  description = "VPC ID in Mumbai"
  type        = string
}

variable "hyderabad_vpc_id" {
  description = "VPC ID in Hyderabad"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}