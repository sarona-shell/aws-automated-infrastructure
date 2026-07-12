Django Notes App: Automated CI/CD & Cloud Infrastructure Pipeline

A robust, production-ready DevOps pipeline that automates the containerization, testing, and infrastructure planning for a Django application. The architecture is designed to securely build and store artifacts before staging a complex, multi-resource cloud blueprint using Infrastructure as Code (IaC).

🚀 Key Achievements & Technical Milestones
*Automated Containerization: Maintained an optimized Docker workflow to build, tag, and layer-cache the Django application dynamically.
*Secure Registry Architecture: Configured automated handshake authentication with Amazon Elastic Container Registry (ECR) to securely push container images.
*Infrastructure as Code (IaC): Orchestrated a 48-resource Terraform blueprint targeting a high-availability AWS architecture (including ECS Fargate, Application Load Balancers, and secure networking).
*Systems & Pipeline Engineering: Successfully managed and optimized a dedicated Jenkins automation server on Linux, troubleshooting advanced system constraints like storage block allocation boundaries and session state caching.


🛠️ Tech Stack & Tools
*Application Framework: Django (Python)

*CI/CD Platform: Jenkins Automation Server (Self-Hosted on Linux/EC2)

*Containerization: Docker & Amazon ECR

*Infrastructure as Code: Terraform

*Target Cloud Provider: Amazon Web Services (AWS ECS Fargate, ALB, VPC)


📋 Pipeline Architecture & Workflow
The Jenkins declarative pipeline executes the following structural phases:

1.Source Code Checkout: Pulls the latest application code and infrastructure manifests from Git.

2.Docker Build & Tag: Packages the Django application into a lightweight container image.

3.Amazon ECR Authentication: Dynamically logs into AWS via the CLI to secure the transmission path.

4.Image Push: Ships the container artifact to Amazon ECR (django-notes-app).

5.Terraform Initialization: Prepares the workspace, initializes providers, and verifies backend modules.

6.Terraform Validation & Plan: Runs speculative execution checks to map out exactly 48 infrastructure components safely prior to live deployment.


🔧 Infrastructure Blueprint (Summary of the 48 Resources)
When executed, the IaC manifests construct a highly available, enterprise-grade cloud footprint:

1.Networking: Custom VPC with isolated Public/Private Subnets across multiple Availability Zones.

2.Compute: Amazon ECS Clusters running on serverless AWS Fargate profiles (eliminating manual EC2 host management).

3.Traffic Routing: An Application Load Balancer (ALB) acting as the single public-facing ingress point, dynamically routing traffic down to the underlying ECS container tasks.

4.Security & Observability: Custom AWS IAM roles adhering to the principle of least privilege, strict Security Group isolation, and central logging via Amazon CloudWatch.


💡 Key Troubleshooting Highlights
Building this pipeline required solving real-world systems engineering bottlenecks:

1.Disk Space Quotas: Resolved Jenkins server execution blocks by adjusting disk monitor constraints (Free Space Threshold limits) and implementing aggressive container system pruning (docker system prune).

2.Session Integrity & Access Routing: Handled dynamic AWS IP address rotation issues by isolating cached browser artifacts and establishing proper configuration file checks (config.xml).

