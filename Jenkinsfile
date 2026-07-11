pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION    = 'us-east-1'
        AWS_ACCOUNT_ID        = '985977710228'
        IMAGE_REPO_NAME       = 'django-notes-app'
    }
    stages {
        stage('Lint & Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform init -backend=false'
                    sh 'terraform fmt -check'
                    sh 'terraform validate'
                }
            }
        }
        stage('Security Scan') {
            steps {
                // Instantly catches wide-open security groups or unencrypted S3 buckets
                sh 'tfsec terraform/' 
            }
        }
        stage('Build App & Push to ECR') {
            steps {
                // 1. Build local docker image
                sh "docker build -t django-notes-app ./django-notes-app"

                // 2. Log into Amazon ECR securely
                sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 985977710228.dkr.ecr.us-east-1.amazonaws.com"

                // 3. Tag the image with Git Commit ID and latest
                sh "docker tag django-notes-app:latest 985977710228.dkr.ecr.us-east-1.amazonaws.com/django-notes-app:${GIT_COMMIT}"
                sh "docker tag django-notes-app:latest 985977710228.dkr.ecr.us-east-1.amazonaws.com/django-notes-app:latest"

                // 4. Push tags to ECR Repository
                sh "docker push 985977710228.dkr.ecr.us-east-1.amazonaws.com/django-notes-app:${GIT_COMMIT}"
                sh "docker push 985977710228.dkr.ecr.us-east-1.amazonaws.com/django-notes-app:latest"
            }
        }
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        stage('Deploy Infrastructure') {
            when { branch 'main' }
            steps {
                dir('terraform') {
                    input message: 'Approve infrastructure deployment?'
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
    }
}