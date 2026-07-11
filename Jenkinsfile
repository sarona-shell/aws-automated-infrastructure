pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-1'
        IMAGE_REPO_NAME    = 'django-notes-app'
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
                sh 'docker build -t $IMAGE_REPO_NAME ./app'
                // Add commands to log into AWS ECR and push image tagging it with git commit ID
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