variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be deployed."
}

variable "bucket" {
  type        = string
  description = "The S3 bucket name for storing Terraform state files."
}

variable "dynamodb_table" {
  type        = string
  description = "The DynamoDB table name for state locking."
}

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod)."
}

variable "vpc_cidr" {
  type        = string
  description = "The foundational CIDR block for the custom VPC."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnets across availability zones."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private subnets across availability zones."
}

variable "container_port" {
  type        = number
  description = "The port the Django container application listens on."
}

variable "container_cpu" {
  type        = number
  description = "Fargate task CPU allocation (256 = 0.25 vCPU)."
}

variable "container_memory" {
  type        = number
  description = "Fargate task memory allocation in MB."
}

variable "alert_email" {
  type        = string
  description = "The operational email address to receive CloudWatch alerts."
  sensitive   = true # Hides the email value from terraform plan outputs
}