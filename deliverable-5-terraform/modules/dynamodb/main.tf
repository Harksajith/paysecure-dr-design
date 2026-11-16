# =====================
# DynamoDB Global Tables
# Always active in both regions
# =====================

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.mumbai, aws.hyderabad]
    }
  }
}

# =====================
# Idempotency Keys Table
# Prevents duplicate payments
# =====================

resource "aws_dynamodb_table" "idempotency_keys" {
  provider         = aws.mumbai
  name             = "${var.project_name}-idempotency-keys"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "txn_id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "txn_id"
    type = "S"
  }

  # Auto expire keys after 24 hours
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # Global table replication to Hyderabad
  replica {
    region_name = "ap-south-2"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name    = "${var.project_name}-idempotency-keys"
    Purpose = "Prevent duplicate payment processing"
  }
}

# =====================
# Sessions Table
# User session storage
# =====================

resource "aws_dynamodb_table" "sessions" {
  provider         = aws.mumbai
  name             = "${var.project_name}-sessions"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "session_id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "session_id"
    type = "S"
  }

  # Sessions expire after 2 hours
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  replica {
    region_name = "ap-south-2"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name    = "${var.project_name}-sessions"
    Purpose = "User session management"
  }
}

# =====================
# Transaction State Table
# Temporary payment state
# =====================

resource "aws_dynamodb_table" "transaction_state" {
  provider         = aws.mumbai
  name             = "${var.project_name}-transaction-state"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "txn_id"
  range_key        = "created_at"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "txn_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  # State expires after 1 hour
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  replica {
    region_name = "ap-south-2"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name    = "${var.project_name}-transaction-state"
    Purpose = "Temporary transaction state during processing"
  }
}

# =====================
# CloudWatch Alarms
# =====================

resource "aws_cloudwatch_metric_alarm" "dynamodb_replication_lag" {
  provider            = aws.mumbai
  alarm_name          = "${var.project_name}-dynamodb-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 5000
  alarm_description   = "DynamoDB replication lag exceeded 5000ms"

  dimensions = {
    TableName   = aws_dynamodb_table.idempotency_keys.name
    ReceivingRegion = "ap-south-2"
  }

  tags = {
    Name = "${var.project_name}-dynamodb-lag-alarm"
  }
}