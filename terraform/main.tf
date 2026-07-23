# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "state_bucket" {
  bucket = var.bucket

  tags = {
    Name        = "My bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Blocks all public access to the state bucket
resource "aws_s3_bucket_public_access_block" "state_bucket_privacy" {
  bucket                  = aws_s3_bucket.state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enables default server-side encryption
# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_encryption" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      # For standard security, AES256 works. 
      # Change to "aws:kms" if you wish to use a Customer Managed Key (CMK) to clear #12 entirely.
      sse_algorithm = "AES256"
    }
  }
}

# tfsec:ignore:aws-dynamodb-enable-recovery
resource "aws_dynamodb_table" "dynamodb_table" {
  name           = var.dynamodb_table
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockId"

  attribute {
    name = "LockId"
    type = "S"
  }

  #Enables server-side encryption using the AWS managed key
  server_side_encryption {
    enabled     = true
    kms_key_arn = null # Defaults to the AWS managed DynamoDB key
  }
}

# High Availability VPC
# tfsec:ignore:aws-ec2-no-excessive-port-access tfsec:ignore:aws-ec2-no-public-ingress-acl tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"
  name    = "note-app-${var.environment}"
  cidr    = var.vpc_cidr

  # Dynamically fetch AZs based on the selected region
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false # Keeps costs low for development environments

}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.0"

  name    = "note-app-alb-${var.environment}"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets #Subnet IDs are calculated automatically at runtime based on your VPC module inputs.

  target_groups = {
    ecs_tasks = {
      backend_protocol  = "HTTP"
      backend_port      = var.container_port
      target_type       = "ip"
      create_attachment = false # Critical: Tells ALB module NOT to manually attach targets since ECS does it dynamically
      health_check = {
        path = "/"
      }
    }
  }
}

# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/django-notes-app-${var.environment}"
  retention_in_days = 30 # Retain logs for 30 days to manage storage costs

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 7.5.0"

  cluster_name = "notes-app-cluster-${var.environment}"

  # Enable Container Insights for built-in container CPU, memory, and network metrics
  cluster_setting = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]

  # Tell the cluster it's allowed to use both standard and spot capacity
  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # The strategy layout for the cluster
  default_capacity_provider_strategy = {
    fargate = {
      capacity_provider = "FARGATE"
      base              = 1
      weight            = 0
    }
    fargate_spot = {
      capacity_provider = "FARGATE_SPOT"
      base              = 0
      weight            = 100
    }
  }

  services = {
    notes-service = {
      # Service-level configurations
      cpu        = var.container_cpu
      memory     = var.container_memory
      subnet_ids = module.vpc.private_subnets

      container_definitions = {
        django-notes-app = {
          image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
          essential = true
          port_mappings = [
            {
              name           = "django-notes-app"
              container_port = var.container_port
              protocol       = "tcp"
            }
          ]

          # Log configuration for ECS tasks to send logs to CloudWatch
          log_configuration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
              "awslogs-region"        = var.aws_region
              "awslogs-stream-prefix" = "django"
            }
          }
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["ecs_tasks"].arn
          container_name   = "django-notes-app"
          container_port   = var.container_port
        }
      }
    }
  }
}

#AWS ECR Repository for Django Notes App Images
# tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "app_repo" {
  name                 = "django-notes-app-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  # Security Scan on Push: Instantly flags vulnerabilities in container dependencies
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


#Lifecycle Policy that automatically cleans up old images

resource "aws_ecr_lifecycle_policy" "repo_policy" {
  repository = aws_ecr_repository.app_repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep only the last 5 images to optimize AWS storage costs",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# SNS Topic for Monitoring Alerts
resource "aws_sns_topic" "alerts" {
  name = "django-app-alerts-${var.environment}"
  
}

# Add your email address to receive alerts
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol = "email"
  endpoint  = var.alert_email # Add respective email addresses to receive alerts.
}

# Alarm 1: High CPU Utilization on ECS Tasks
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name                = "ecs-high-cpu-${var.environment}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 85
  alarm_description         = "Triggers when ECS CPU utilization exceeds 85% for 2 consecutive minutes."
  alarm_actions             = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = "notes-service"
  }
}

# Alarm 2: High Memory Utilization on ECS Tasks
resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name          = "ecs-high-memory-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Triggers when ECS Memory utilization exceeds 85% for 2 consecutive minutes."
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = "notes-service"
  }
}

# Alarm 3: Application Load Balancer HTTP 5XX Errors (Backend Failures)
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "alb-high-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Triggers when ALB registers more than 10 5xx errors from Django in 1 minute."
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = module.alb.arn_suffix
  }
}

# Alarm 4: Zero Healthy Tasks in Target Group
resource "aws_cloudwatch_metric_alarm" "no_healthy_tasks" {
  alarm_name          = "alb-zero-healthy-tasks-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "CRITICAL: No healthy Django tasks are available to receive traffic!"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TargetGroup  = module.alb.target_groups["ecs_tasks"].arn_suffix
    LoadBalancer = module.alb.arn_suffix
  }
}