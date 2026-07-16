pipeline {
    agent any
    
    options {
        // Prevents parallel runs from colliding or messing up the Terraform state
        disableConcurrentBuilds()
        ansiColor('xterm') 
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        IMAGE_REPO_NAME    = 'django-notes-app'
        
        // We still fetch the Account ID dynamically via the shell to keep it out of source code.
        AWS_ACCOUNT_ID     = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
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
                // Note: Assumes 'tfsec' is installed on your Jenkins runner
                sh 'tfsec terraform/' 
            }
        }
        
        stage('Build App & Push to ECR') {
            steps {
                withAWS(region: "${AWS_DEFAULT_REGION}") {
                    
                    // 1. Authenticate Docker with AWS ECR (Crucial Missing Step!)
                    sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"

                    // 2. Build local docker image
                    sh "docker build -t ${IMAGE_REPO_NAME} ./django-notes-app"

                    // 3. Tag the image with Git Commit ID and latest
                    sh "docker tag ${IMAGE_REPO_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${GIT_COMMIT}"
                    sh "docker tag ${IMAGE_REPO_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:latest"

                    // 4. Push tags to ECR Repository
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${GIT_COMMIT}"
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:latest"
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    withAWS(region: "${AWS_DEFAULT_REGION}") {
                        sh 'terraform init'
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }
        
        stage('Deploy Infrastructure') {
            when { branch 'main' }
            steps {
                dir('terraform') {
                    input message: 'Approve infrastructure deployment?'
                    
                    withAWS(region: "${AWS_DEFAULT_REGION}") {
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }
    }
}