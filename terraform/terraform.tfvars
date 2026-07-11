# Regional Settings
aws_region  = "us-east-1"
environment = "dev"
bucket         = "my-django-note-bucket-sarona-2026"
dynamodb_table = "terraform-state-locking"
# Network IP Layout
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

# ECS Fargate App Sizing Configuration
container_port   = 8000
container_cpu    = 256
container_memory = 512