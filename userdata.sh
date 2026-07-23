#!/bin/bash
# Redirect all output to a log file for easy debugging/troubleshooting
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=================== STARTING SYSTEM BOOTSTRAP ==================="

# 1. Update system packages and apply security patches
apt-get update -y
apt-get upgrade -y

# Install common utilities
apt-get install -y curl unzip apt-transport-https ca-certificates gnupg lsb-release jq

# 2. Dynamic Metadata Retrieval using IMDSv2 (Secure Token)
echo "Retrieving AWS Instance Metadata..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
LOCAL_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
echo "Bootstrapping Instance: $INSTANCE_ID with Private IP: $LOCAL_IP"

# 3. Install Docker Engine (FIXED: Corrected sources.list.d typo)
echo "Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker

# 4. Install Jenkins & Java (FIXED: Updated to the valid jenkins.io-2026.key)
echo "Installing Jenkins..."
apt-get install -y openjdk-21-jdk

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins
systemctl enable jenkins
systemctl start jenkins

# Add jenkins user to the docker group so it can run docker commands without sudo
usermod -aG docker jenkins
systemctl restart jenkins

# 5. Install AWS CLI v2
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# 6. Install Terraform (Separated out for system cache reliability)
echo "Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com/gpg $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Force clean update before installing
sudo apt-get update -y
sudo apt-get install terraform -y

# 7. Install tfsec (FIXED: Pinned to the last stable release to avoid GitHub API rate limit blocks)
echo "Installing tfsec..."
TFSEC_VERSION="v1.28.13" 
curl -Lo tfsec "https://github.com/aquasecurity/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64"
chmod +x tfsec
mv tfsec /usr/local/bin/

echo "=================== BOOTSTRAP COMPLETE ==================="
# Print Jenkins Initial Admin Password to log for easy setup retrieval
echo "Jenkins Initial Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword