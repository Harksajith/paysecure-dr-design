# =====================
# Aurora Global Database
# Primary: Mumbai
# Secondary: Hyderabad
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
# Security Groups
# =====================

resource "aws_security_group" "aurora_mumbai" {
  provider    = aws.mumbai
  name        = "${var.project_name}-aurora-mumbai-sg"
  description = "Security group for Aurora Mumbai"
  vpc_id      = var.mumbai_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "PostgreSQL from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name = "${var.project_name}-aurora-mumbai-sg"
  }
}

resource "aws_security_group" "aurora_hyderabad" {
  provider    = aws.hyderabad
  name        = "${var.project_name}-aurora-hyderabad-sg"
  description = "Security group for Aurora Hyderabad"
  vpc_id      = var.hyderabad_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "PostgreSQL from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name = "${var.project_name}-aurora-hyderabad-sg"
  }
}

# =====================
# Subnet Groups
# =====================

resource "aws_db_subnet_group" "mumbai" {
  provider   = aws.mumbai
  name       = "${var.project_name}-aurora-mumbai"
  subnet_ids = var.mumbai_subnet_ids

  tags = {
    Name = "${var.project_name}-aurora-mumbai-subnet-group"
  }
}

resource "aws_db_subnet_group" "hyderabad" {
  provider   = aws.hyderabad
  name       = "${var.project_name}-aurora-hyderabad"
  subnet_ids = var.hyderabad_subnet_ids

  tags = {
    Name = "${var.project_name}-aurora-hyderabad-subnet-group"
  }
}

# =====================
# Aurora Global Cluster
# =====================

resource "aws_rds_global_cluster" "paysecure" {
  provider                  = aws.mumbai
  global_cluster_identifier = "${var.project_name}-global-cluster"
  engine                    = "aurora-postgresql"
  engine_version            = "15.4"
  database_name             = var.db_name
  storage_encrypted         = true

  lifecycle {
    prevent_destroy = true
  }
}

# =====================
# Mumbai Primary Cluster
# =====================

resource "aws_rds_cluster" "mumbai" {
  provider                  = aws.mumbai
  cluster_identifier        = "${var.project_name}-mumbai"
  engine                    = "aurora-postgresql"
  engine_version            = "15.4"
  global_cluster_identifier = aws_rds_global_cluster.paysecure.id
  database_name             = var.db_name
  master_username           = var.db_username
  master_password           = var.db_password
  db_subnet_group_name      = aws_db_subnet_group.mumbai.name
  vpc_security_group_ids    = [aws_security_group.aurora_mumbai.id]
  storage_encrypted         = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-mumbai-final"

  # Backup
  backup_retention_period = 7
  preferred_backup_window = "02:00-03:00"

  # Maintenance
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  # Enhanced monitoring
  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]

  tags = {
    Name = "${var.project_name}-aurora-mumbai"
    Role = "Primary"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_rds_cluster_instance" "mumbai" {
  count              = 2
  provider           = aws.mumbai
  identifier         = "${var.project_name}-mumbai-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.mumbai.id
  instance_class     = var.instance_class
  engine             = "aurora-postgresql"
  engine_version     = "15.4"

  # Performance Insights
  performance_insights_enabled = true

  # Enhanced Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  tags = {
    Name = "${var.project_name}-aurora-mumbai-${count.index + 1}"
  }
}

# =====================
# Hyderabad Secondary Cluster
# =====================

resource "aws_rds_cluster" "hyderabad" {
  provider                  = aws.hyderabad
  cluster_identifier        = "${var.project_name}-hyderabad"
  engine                    = "aurora-postgresql"
  engine_version            = "15.4"
  global_cluster_identifier = aws_rds_global_cluster.paysecure.id
  db_subnet_group_name      = aws_db_subnet_group.hyderabad.name
  vpc_security_group_ids    = [aws_security_group.aurora_hyderabad.id]
  storage_encrypted         = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-hyderabad-final"

  # Note: No master_username/password for secondary
  # It inherits from global cluster

  backup_retention_period      = 7
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]

  tags = {
    Name = "${var.project_name}-aurora-hyderabad"
    Role = "Secondary"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [aws_rds_cluster.mumbai]
}

resource "aws_rds_cluster_instance" "hyderabad" {
  count              = 1
  provider           = aws.hyderabad
  identifier         = "${var.project_name}-hyderabad-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.hyderabad.id
  instance_class     = var.instance_class
  engine             = "aurora-postgresql"
  engine_version     = "15.4"

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring_hyd.arn

  tags = {
    Name = "${var.project_name}-aurora-hyderabad-${count.index + 1}"
  }
}

# =====================
# IAM Role for Monitoring
# =====================

resource "aws_iam_role" "rds_monitoring" {
  provider = aws.mumbai
  name     = "${var.project_name}-rds-monitoring-mumbai"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  provider   = aws.mumbai
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role" "rds_monitoring_hyd" {
  provider = aws.hyderabad
  name     = "${var.project_name}-rds-monitoring-hyderabad"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_hyd" {
  provider   = aws.hyderabad
  role       = aws_iam_role.rds_monitoring_hyd.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# =====================
# CloudWatch Alarms
# =====================

resource "aws_cloudwatch_metric_alarm" "aurora_replication_lag" {
  provider            = aws.hyderabad
  alarm_name          = "${var.project_name}-aurora-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "AuroraGlobalDBReplicationLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1000
  alarm_description   = "Aurora replication lag exceeded 1000ms"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.hyderabad.cluster_identifier
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = {
    Name = "${var.project_name}-aurora-lag-alarm"
  }
}