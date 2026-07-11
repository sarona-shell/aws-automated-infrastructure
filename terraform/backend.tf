/* terraform {
  backend "s3" {
    bucket         = "my-django-note-bucket-sarona-2026" # Must be globally unique
    key            = "dev/django-notes-app/terraform.tfstate"
    region         = "us-east-1"
    
    # Enable state locking via DynamoDB
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
} */