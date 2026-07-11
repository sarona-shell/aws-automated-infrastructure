pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ACCOUNT_ID        = '9859-7771-0228'
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
        // 1. Build the local docker image from your app folder
                sh 'docker build -t $IMAGE_REPO_NAME ./django-notes-app'

        // 2. Log into Amazon ECR securely using your AWS environment keys
                sh 'aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com'

        // 3. Tag the image with the unique Git Commit ID (and as latest)
                sh 'docker tag $IMAGE_REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:${GIT_COMMIT}'
                sh 'docker tag $IMAGE_REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:latest'

        // 4. Push both tags to your ECR Repository
                sh 'docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:${GIT_COMMIT}'
                sh 'docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:latest'
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