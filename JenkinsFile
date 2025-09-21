pipeline {
    agent any

    environment {
        // SSH Connectivity Variables
        CONST_EC2_IP_ADDRESS = "43.205.239.149"
        CONST_EC2_USER       = "ubuntu"

         // AWS & Infra Credentials
        CONST_AWS_CONFIGURE_REGION_ID = "ap-south-1"
        CONST_AWS_CONFIGURE_OUTPUT_FORMAT = "json"
        CONST_AWS_ECR_REPOSITORY_NAME = "jl-python-flask-repository"
        CONST_AWS_ECR_PYFLASK_TAG = "jlpyflask"
        CONST_AWS_ECR_PYFLASK_PORT = 5000
        CONST_TF_EKS_S3_BUCKET_NAME = "jl-pyflask-bucket"
        CONST_TF_EKS_CLUSTER_NAME = "jl-pyflask-eks-cluster"
        CONST_TF_EKS_CLUSTER_NODE_NAME = "jl_eks_pyflask_node_role"
        CONST_TF_EKS_CLUSTER_NODE_GROUP_NAME = "jl_eks_pyflask_node_group_role"
        CONST_TF_EKS_NODE_GROUP_NAME = "jl_eks_pyflask_node_group"
        CONST_TF_EKS_NODE_TYPE = "t3.medium"
        CONST_TF_EKS_NODE_COUNT = 2
        CONST_TF_EKS_VPC_ID = "vpc-0056d809452f9f8ea"
        CONST_TF_EKS_SUBNET1 = "172.31.224.0/20"
        CONST_TF_EKS_SUBNET2 = "172.31.240.0/20"

        // GITHUB
        CONST_GITHUB_CLONE_URL = "https://github.com/JOYSTON-LEWIS/Placement-Readiness-Test-HV.git"

        // SECRETS
        SECRETS_GITHUB_PAT_TOKEN = credentials('SECRETS_GITHUB_PAT_TOKEN')

        // DEPLOYMENT SECTION
        CONST_K8S_NAMESPACE = "pyflask-app"
        CONST_K8S_APP_NAME = "jl-pyflask-service"
        CONST_DEPLOY_SERVICE_TYPE = "ClusterIP"

    }

    stages {

        stage('Build: Step 01: Install Tools on EC2') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'SECRETS_AWS_CONFIGURE_CREDENTIALS',
                    accessKeyVariable: 'SECRETS_AWS_CONFIGURE_ACCESS_KEY',
                    secretKeyVariable: 'SECRETS_AWS_CONFIGURE_SECRET_KEY'
                ]]) {
                    sshagent (credentials: ['SECRETS_EC2_SSH_PRIVATE_KEY']) {
                    script {
                        def SCRIPT_SSH_IP = env.CONST_EC2_IP_ADDRESS
                        def SCRIPT_SSH_USER = env.CONST_EC2_USER
                        def SCRIPT_ACCESS_KEY = SECRETS_AWS_CONFIGURE_ACCESS_KEY
                        def SCRIPT_SECRET_KEY = SECRETS_AWS_CONFIGURE_SECRET_KEY
                        def SCRIPT_REGION = env.CONST_AWS_CONFIGURE_REGION_ID
                        def SCRIPT_OUTPUT = env.CONST_AWS_CONFIGURE_OUTPUT_FORMAT
                        sh """
                        ssh -o StrictHostKeyChecking=no ${SCRIPT_SSH_USER}@${SCRIPT_SSH_IP} <<EOF
echo "✅ Connected to EC2 Success"
echo "✅ Step Install Tools on EC2 Start"

echo ">>> Installing Tools on EC2..."

# Create temporary folder for downloads
mkdir -p ~/install_temp
cd ~/install_temp

# Update system and install packages
sudo apt update -y
sudo apt upgrade -y
# sudo apt-get install -y docker.io python3-pip

# Installing curl
if ! command -v curl &> /dev/null; then
    sudo apt-get install -y --install-recommends curl
else
    echo "✅ package: curl already installed, skipping..."
fi

# Installing git
if ! command -v git &> /dev/null; then
    sudo apt-get install -y --install-recommends git
else
    echo "✅ package: git already installed, skipping..."
fi

# Installing unzip
if ! command -v unzip &> /dev/null; then
    sudo apt-get install -y --install-recommends unzip
else
    echo "✅ package: unzip already installed, skipping..."
fi

# Installing jq
if ! command -v jq &> /dev/null; then
    sudo apt-get install -y --install-recommends jq
else
    echo "✅ package: jq already installed, skipping..."
fi

# Install Python Section
if ! command -v python3 &> /dev/null; then
    sudo apt-get install -y --install-recommends python3
else
    echo "✅ package: Python3 already installed, skipping..."
fi

# Python package manager
if ! command -v pip3 &> /dev/null; then
    sudo apt-get install -y --install-recommends python3-pip
else
    echo "✅ package: pip3 already installed, skipping..."
fi

# Install requests library for HTTP/API calls
if ! pip3 show requests >/dev/null 2>&1 || ! pip3 show requests | grep -q "Version: 2.31.0"; then
    python3 -m pip install --upgrade requests==2.31.0 --break-system-packages --no-progress-bar
else
    echo "✅ package: requests library already installed, skipping..."
fi

# Install Docker Section
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y --install-recommends docker.io
    # Add ${SCRIPT_SSH_USER} to docker group
    sudo usermod -aG docker ${SCRIPT_SSH_USER}
else
    echo "✅ package: Docker already installed, skipping..."
fi

# Install Kubernetes Section
if ! command -v kubectl &> /dev/null; then
    # Fix kernel file protection
    sudo sysctl fs.protected_regular=0
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/v1.33.1/bin/linux/amd64/kubectl"
    chmod +x kubectl && sudo mv kubectl /usr/local/bin/
else
    echo "✅ package: Kubernetes(kubectl) already installed, skipping..."
fi

# Install Helm
if ! command -v helm &> /dev/null; then
    curl -Lo helm_install.tar.gz "https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz"
    tar -xvzf helm_install.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
else
    echo "✅ package: Helm already installed, skipping..."
fi

# Install AWS CLI Section
if ! command -v aws &> /dev/null; then
    rm -rf aws awscliv2.zip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.15.0.zip" -o "awscliv2.zip"
    unzip -o awscliv2.zip
    sudo ./aws/install
    # Configure AWS CLI
    aws configure set aws_access_key_id "${SCRIPT_ACCESS_KEY}"
    aws configure set aws_secret_access_key "${SCRIPT_SECRET_KEY}"
    aws configure set region "${SCRIPT_REGION}"
    aws configure set output "${SCRIPT_OUTPUT}"
else
    echo "✅ package: AWS CLI already installed, skipping..."
fi

# Install Terraform Section
if ! command -v terraform &> /dev/null; then
    curl -fsSL "https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip" -o terraform.zip
    unzip -o terraform.zip
    sudo mv terraform /usr/local/bin/
else
    echo "✅ package: Terraform already installed, skipping..."
fi

# Install EKS Section
if ! command -v eksctl &> /dev/null; then
    curl -Lo eksctl_install.tar.gz "https://github.com/weaveworks/eksctl/releases/download/v0.150.0/eksctl_Linux_amd64.tar.gz"
    tar -xvzf eksctl_install.tar.gz
    sudo mv eksctl /usr/local/bin/eksctl
else
    echo "✅ package: eksctl already installed, skipping..."
fi

# Cleanup all downloaded archives and extracted temp folders
cd ~
rm -rf ~/install_temp
sudo apt-get clean
sudo rm -rf ~/.cache

echo "✅ Packages Installed and Updated Sucessfully"
echo "✅ Step Install Tools on EC2 End"

EOF
                        """
                        }
                    }
                }
            }
        }

stage('Test: Step 01: Verify Tools on EC2') {
    steps {
        sshagent (credentials: ['SECRETS_EC2_SSH_PRIVATE_KEY']) {
            sh """
ssh -o StrictHostKeyChecking=no ${CONST_EC2_USER}@${CONST_EC2_IP_ADDRESS} <<'EOF'
  echo "🔍 Verifying installed tools on EC2..."

  check_tool() {
    local cmd=\$1
    local name=\$2
    if command -v \$cmd &> /dev/null; then
      echo "✅ \$name is installed"
    else
      echo "❌ \$name is missing"
      exit 1
    fi
  }

  check_tool curl "curl"
  check_tool git "git"
  check_tool unzip "unzip"
  check_tool jq "jq"
  check_tool python3 "python3"
  check_tool pip3 "pip3"
  check_tool docker "docker"
  check_tool kubectl "kubectl"
  check_tool helm "helm"
  check_tool aws "aws cli"
  check_tool terraform "terraform"
  check_tool eksctl "eksctl"

  # Special check for requests library
  if pip3 show requests >/dev/null 2>&1; then
    VERSION=\$(pip3 show requests | grep Version | awk '{print \$2}')
    echo "✅ requests library installed (version: \$VERSION)"
  else
    echo "❌ requests library is missing"
    exit 1
  fi

  echo "🎉 All required tools are installed successfully!"
EOF
            """
        }
    }
}



stage('Build: Common Step 02: Terraform ECR and EKS Cluster Creation') {
    steps {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'SECRETS_AWS_CONFIGURE_CREDENTIALS',
            accessKeyVariable: 'SECRETS_AWS_CONFIGURE_ACCESS_KEY',
            secretKeyVariable: 'SECRETS_AWS_CONFIGURE_SECRET_KEY'
        ]]) {
            sshagent(['SECRETS_EC2_SSH_PRIVATE_KEY']) {
                script {
                    def SCRIPT_SSH_IP = env.CONST_EC2_IP_ADDRESS
                    def SCRIPT_SSH_USER = env.CONST_EC2_USER
                    def SCRIPT_ACCESS_KEY = SECRETS_AWS_CONFIGURE_ACCESS_KEY
                    def SCRIPT_SECRET_KEY = SECRETS_AWS_CONFIGURE_SECRET_KEY
                    def SCRIPT_S3_BUCKET = env.CONST_TF_EKS_S3_BUCKET_NAME
                    def SCRIPT_REGION = env.CONST_AWS_CONFIGURE_REGION_ID
                    def SCRIPT_VPC_ID = env.CONST_TF_EKS_VPC_ID
                    def SCRIPT_SUBNET1 = env.CONST_TF_EKS_SUBNET1
                    def SCRIPT_SUBNET2 = env.CONST_TF_EKS_SUBNET2
                    def SCRIPT_CLUSTER_NAME = env.CONST_TF_EKS_CLUSTER_NAME
                    def SCRIPT_CLUSTER_ROLE_NAME = env.CONST_TF_EKS_CLUSTER_NODE_NAME
                    def SCRIPT_NODE_ROLE_NAME = env.CONST_TF_EKS_CLUSTER_NODE_GROUP_NAME
                    def SCRIPT_NODE_GROUP_NAME = env.CONST_TF_EKS_NODE_GROUP_NAME
                    def SCRIPT_NODE_COUNT = env.CONST_TF_EKS_NODE_COUNT
                    def SCRIPT_NODE_TYPE = env.CONST_TF_EKS_NODE_TYPE
                    sh """
ssh -o StrictHostKeyChecking=no ${SCRIPT_SSH_USER}@${SCRIPT_SSH_IP} 'bash -s' <<'ENDSSH'
set -euo pipefail
echo "✅ Connected to EC2 Success"
echo "✅ Step Terraform ECR and EKS Cluster Creation Start"

cd ~
mkdir -p terraform-eks-configurations
cd terraform-eks-configurations

# --- Create main.tf using provided subnets ---
cat > main.tf << 'EOT'
terraform {
  backend "s3" {
    bucket = "${SCRIPT_S3_BUCKET}"
    key    = "eks/terraform.tfstate"
    region = "${SCRIPT_REGION}"
  }
}

provider "aws" {
  region     = "${SCRIPT_REGION}"
  access_key = "${SCRIPT_ACCESS_KEY}"
  secret_key = "${SCRIPT_SECRET_KEY}"
}

data "aws_vpc" "selected" { id = "${SCRIPT_VPC_ID}" }

data "aws_availability_zones" "available" {}

resource "aws_subnet" "eks_subnet" {
  count             = 2
  vpc_id            = data.aws_vpc.selected.id
  cidr_block        = element(["${SCRIPT_SUBNET1}", "${SCRIPT_SUBNET2}"], count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "eks-subnet-\${count.index}" }
}

# -------------------
# Terraform-managed Cluster IAM Role
# -------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "${SCRIPT_CLUSTER_ROLE_NAME}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach required AWS managed policies to Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Optional but recommended for managing VPC resources like ENIs
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# -------------------
# Terraform-managed Node IAM Role
# -------------------
resource "aws_iam_role" "eks_node_role" {
  name = "${SCRIPT_NODE_ROLE_NAME}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_ro_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -------------------
# EKS Cluster + Nodegroup
# -------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${SCRIPT_CLUSTER_NAME}"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.eks_subnet[*].id
  }

  depends_on = [
    aws_subnet.eks_subnet,
    aws_iam_role.eks_cluster_role
  ]
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${SCRIPT_NODE_GROUP_NAME}"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.eks_subnet[*].id

  scaling_config {
    desired_size = ${SCRIPT_NODE_COUNT}
    max_size     = ${SCRIPT_NODE_COUNT}
    min_size     = 1
  }

  instance_types = ["${SCRIPT_NODE_TYPE}"]

  lifecycle {
    create_before_destroy = true
  }
}
EOT

# --- Run Terraform ---
terraform init -reconfigure
terraform apply -auto-approve

echo "✅ EKS Cluster + Nodegroup created successfully"

# Update kubeconfig
aws eks update-kubeconfig \
  --region ${SCRIPT_REGION} \
  --name ${SCRIPT_CLUSTER_NAME}

# Wait for nodes to be Ready
echo "⏳ Waiting for EKS nodes to be Ready..."
kubectl wait --for=condition=Ready node --all --timeout=10m

# Show nodes and services
kubectl get nodes
kubectl get svc

# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
echo "⏳ Waiting for metrics-server to be Ready..."
kubectl wait --for=condition=Available deployment metrics-server -n kube-system --timeout=5m

echo "✅ Terraform ECR and EKS Cluster Creation Done Sucessfully"
echo "✅ Step Terraform ECR and EKS Cluster Creation End"

ENDSSH
                    """
                }
            }
        }
    }
}


stage('Test: Step 02: Verify S3, ECR, and EKS Cluster') {
    steps {
        sshagent (credentials: ['SECRETS_EC2_SSH_PRIVATE_KEY']) {
            sh """
ssh -o StrictHostKeyChecking=no ${CONST_EC2_USER}@${CONST_EC2_IP_ADDRESS} <<'EOF'
  set -euo pipefail
  echo "🔍 Verifying AWS Infra (S3, ECR, EKS)..."

  # --- Verify S3 Bucket ---
  if aws s3api head-bucket --bucket ${CONST_TF_EKS_S3_BUCKET_NAME} --region ${CONST_AWS_CONFIGURE_REGION_ID} 2>/dev/null; then
    echo "✅ S3 Bucket exists: ${CONST_TF_EKS_S3_BUCKET_NAME}"
  else
    echo "❌ S3 Bucket missing: ${CONST_TF_EKS_S3_BUCKET_NAME}"
    exit 1
  fi

  # --- Verify ECR Repository ---
  if aws ecr describe-repositories --repository-names ${CONST_AWS_ECR_REPOSITORY_NAME} --region ${CONST_AWS_CONFIGURE_REGION_ID} >/dev/null 2>&1; then
    echo "✅ ECR Repository exists: ${CONST_AWS_ECR_REPOSITORY_NAME}"
  else
    echo "❌ ECR Repository missing: ${CONST_AWS_ECR_REPOSITORY_NAME}"
    exit 1
  fi

  # --- Verify EKS Cluster ---
  if aws eks describe-cluster --name ${CONST_TF_EKS_CLUSTER_NAME} --region ${CONST_AWS_CONFIGURE_REGION_ID} >/dev/null 2>&1; then
    echo "✅ EKS Cluster exists: ${CONST_TF_EKS_CLUSTER_NAME}"
    kubectl get nodes
  else
    echo "❌ EKS Cluster missing: ${CONST_TF_EKS_CLUSTER_NAME}"
    exit 1
  fi

  echo "🎉 Infra verification completed successfully"
EOF
            """
        }
    }
}


        stage('Build: Step 03: Git Pull, Dockerize & Push Flask App to ECR') {
            steps {
                withCredentials([[ 
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'SECRETS_AWS_CONFIGURE_CREDENTIALS',
                    accessKeyVariable: 'SECRETS_AWS_CONFIGURE_ACCESS_KEY',
                    secretKeyVariable: 'SECRETS_AWS_CONFIGURE_SECRET_KEY'
                ]]) {
                    sshagent (credentials: ['SECRETS_EC2_SSH_PRIVATE_KEY']) {
                        script {
                            def SCRIPT_SSH_IP = env.CONST_EC2_IP_ADDRESS
                            def SCRIPT_SSH_USER = env.CONST_EC2_USER
                            def SCRIPT_GIT_URL = env.CONST_GITHUB_CLONE_URL
                            def SCRIPT_PAT_TOKEN = env.SECRETS_GITHUB_PAT_TOKEN
                            def SCRIPT_REGION = env.CONST_AWS_CONFIGURE_REGION_ID
                            def SCRIPT_REPO_NAME = env.CONST_AWS_ECR_REPOSITORY_NAME
                            def SCRIPT_TAG = env.CONST_AWS_ECR_PYFLASK_TAG
                            def SCRIPT_PORT = env.CONST_AWS_ECR_PYFLASK_PORT

                            def SCRIPT_AWS_ACCOUNT_ID = sh(
                                script: """
                                    ssh -o StrictHostKeyChecking=no ${SCRIPT_SSH_USER}@${SCRIPT_SSH_IP} \
                                    'aws sts get-caller-identity --query Account --output text'
                                """,
                                returnStdout: true
                            ).trim()
                            // Process GitHub repo name
                            def SCRIPT_PARTIAL_REPO = sh(
                                script: """echo "${SCRIPT_GIT_URL}" | sed -e 's|https://github.com/||' -e 's|\\.git\$||'""",
                                returnStdout: true
                            ).trim()

                            // Check if repo is public or private
                            def SCRIPT_PUBLIC_PRIVATE_CHECK = sh(
                                script: "curl -s -o /dev/null -w \"%{http_code}\" https://api.github.com/repos/${SCRIPT_PARTIAL_REPO}",
                                returnStdout: true
                            ).trim()

                            def SCRIPT_REPO_FOLDER = sh(
                                script: """basename -s .git ${env.CONST_GITHUB_CLONE_URL}""",
                                returnStdout: true
                            ).trim()

                            sh """
                            ssh -o StrictHostKeyChecking=no ${SCRIPT_SSH_USER}@${SCRIPT_SSH_IP} <<EOF
echo "✅ Connected to EC2 Success"
echo "✅ Step Git Pull & Dockerize Flask App Start"

# Clean old repo
cd /home/${SCRIPT_SSH_USER}
rm -rf ${SCRIPT_REPO_FOLDER}

# Clone repo (public or private)
if [ "${SCRIPT_PUBLIC_PRIVATE_CHECK}" = "200" ]; then
    echo "✅ Public repository"
    git clone "${SCRIPT_GIT_URL}"
elif [ "${SCRIPT_PUBLIC_PRIVATE_CHECK}" = "404" ]; then
    echo "🔒 Private repository"
    git clone "https://${SCRIPT_PAT_TOKEN}@github.com/${SCRIPT_PARTIAL_REPO}.git"
fi

cd ${SCRIPT_REPO_FOLDER}
git checkout main

# Show repo contents
echo "Current Repo Directory Contents:"
ls -la

# Create Dockerfile
echo "Generating Dockerfile..."
cat <<DOCKERFILE > Dockerfile
FROM python:3.13.1-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE ${SCRIPT_PORT}
CMD ["python", "app.py"]
DOCKERFILE

# Build & Push Docker image
IMAGE_URI=${SCRIPT_AWS_ACCOUNT_ID}.dkr.ecr.${SCRIPT_REGION}.amazonaws.com/${SCRIPT_REPO_NAME}:${SCRIPT_TAG}

aws ecr describe-repositories --repository-names ${SCRIPT_REPO_NAME} >/dev/null 2>&1 || \
aws ecr create-repository --repository-name ${SCRIPT_REPO_NAME}

echo "Logging into ECR..."
aws ecr get-login-password --region ${SCRIPT_REGION} | docker login --username AWS --password-stdin ${SCRIPT_AWS_ACCOUNT_ID}.dkr.ecr.${SCRIPT_REGION}.amazonaws.com

echo "Running docker build..."
docker build -t ${SCRIPT_AWS_ACCOUNT_ID}.dkr.ecr.${SCRIPT_REGION}.amazonaws.com/${SCRIPT_REPO_NAME}:${SCRIPT_TAG} .

echo "Running docker push..."
docker push ${SCRIPT_AWS_ACCOUNT_ID}.dkr.ecr.${SCRIPT_REGION}.amazonaws.com/${SCRIPT_REPO_NAME}:${SCRIPT_TAG}

echo "✅ Flask Docker image pushed successfully: \${IMAGE_URI}"
echo "✅ Step Git Pull, Dockerize & Push Flask App End"

EOF
                            """
                        }
                    }
                }
            }
        }


stage('Test: Step 03: Verify Fresh Image in ECR') {
    steps {
        sshagent (credentials: ['SECRETS_EC2_SSH_PRIVATE_KEY']) {
            script {
                def SCRIPT_SSH_IP   = env.CONST_EC2_IP_ADDRESS
                def SCRIPT_SSH_USER = env.CONST_EC2_USER
                def SCRIPT_REGION   = env.CONST_AWS_CONFIGURE_REGION_ID
                def SCRIPT_REPO_NAME = env.CONST_AWS_ECR_REPOSITORY_NAME
                def SCRIPT_TAG      = env.CONST_AWS_ECR_PYFLASK_TAG

                sh """
ssh -o StrictHostKeyChecking=no ${SCRIPT_SSH_USER}@${SCRIPT_SSH_IP} <<'EOF'
  echo "🔍 Verifying that Docker image was pushed recently..."

  IMAGE_DETAIL=\$(aws ecr describe-images \
    --repository-name ${SCRIPT_REPO_NAME} \
    --image-ids imageTag=${SCRIPT_TAG} \
    --region ${SCRIPT_REGION} \
    --query 'imageDetails[0].imagePushedAt' \
    --output text 2>/dev/null)

  if [ -z "\$IMAGE_DETAIL" ] || [ "\$IMAGE_DETAIL" = "None" ]; then
    echo "❌ No image with tag ${SCRIPT_TAG} found in repo ${SCRIPT_REPO_NAME}"
    exit 1
  fi

  echo "✅ Image pushed at: \$IMAGE_DETAIL"

  # Convert times to epoch for comparison
  PUSH_TIME=\$(date -d "\$IMAGE_DETAIL" +%s)
  NOW_TIME=\$(date +%s)
  DIFF_MIN=\$(( (NOW_TIME - PUSH_TIME) / 60 ))

  echo "⏳ Time difference: \$DIFF_MIN minutes ago"

  if [ \$DIFF_MIN -le 2 ]; then
    echo "🎉 Fresh image was created and pushed within last 2 minutes!"
  else
    echo "⚠️ Image exists but was pushed more than 2 minutes ago."
    exit 1
  fi
EOF
                """
            }
        }
    }
}



stage('Build: Step 04: Kubernetes Deployment with LoadBalancer') {
    steps {
        sshagent (credentials: ['SECRETS_EC2_SSH_PRIVATE_KEY']) {
            script {
                def SCRIPT_SSH_IP   = env.CONST_EC2_IP_ADDRESS
                def SCRIPT_SSH_USER = env.CONST_EC2_USER
                def SCRIPT_AWS_ACCOUNT_ID = "975050024946" // replace with your AWS Account ID

                sh """
                ssh -o StrictHostKeyChecking=no ${SCRIPT_SSH_USER}@${SCRIPT_SSH_IP} <<'EOF'
                  set -euo pipefail
                  echo "✅ Connected to EC2 Success"
                  echo "🚀 Step 04: Deploying Flask App to EKS"

                  mkdir -p /home/ubuntu/kubernetes-deployment
                  cd /home/ubuntu/kubernetes-deployment

                  # --- deployment.yaml ---
                  cat > deployment.yaml <<DEPLOY
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jl-flask-app
  namespace: pyflask-app
  labels:
    app: jl-flask-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: jl-flask-app
  template:
    metadata:
      labels:
        app: jl-flask-app
    spec:
      containers:
      - name: jl-flask-app
        image: ${SCRIPT_AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/jl-python-flask-repository:jlpyflask
        imagePullPolicy: Always
        ports:
        - containerPort: 5000
DEPLOY

                  # --- service.yaml ---
                  cat > service.yaml <<SERVICE
apiVersion: v1
kind: Service
metadata:
  name: jl-flask-service
  namespace: pyflask-app
spec:
  selector:
    app: jl-flask-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: LoadBalancer
SERVICE

                  # Ensure namespace exists
                  kubectl create namespace pyflask-app --dry-run=client -o yaml | kubectl apply -f -

                  # Apply and restart
                  kubectl apply -f deployment.yaml
                  kubectl apply -f service.yaml
                  kubectl rollout restart deployment jl-flask-app -n pyflask-app
                  kubectl rollout status deployment jl-flask-app -n pyflask-app

                  echo "✅ Flask App Deployment Successful"
                  kubectl get pods -n pyflask-app
                  kubectl get svc -n pyflask-app

                  # Wait for ELB hostname
                  echo "⏳ Waiting for ELB External IP..."
                  SERVICE_URL=""
                  for i in {1..30}; do
                    SERVICE_URL=\$(kubectl get svc jl-flask-service -n pyflask-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
                    if [ ! -z "\$SERVICE_URL" ]; then
                      echo "🌍 Flask App URL: http://\$SERVICE_URL"
                      break
                    fi
                    echo "Still waiting... (\$i/30)"
                    sleep 20
                  done

                  # Final safety: always exit cleanly
                  echo "✅ Step Kubernetes Deployment with LoadBalancer done Successfully"
                  
EOF
                """
            }
        }
    }
}


stage('Test: Step 04: Verify Kubernetes Deployment with LoadBalancer') {
    steps {
        sshagent (credentials: ['SECRETS_EC2_SSH_PRIVATE_KEY']) {
            script {
                def SCRIPT_SSH_IP   = env.CONST_EC2_IP_ADDRESS
                def SCRIPT_SSH_USER = env.CONST_EC2_USER

                sh """
                ssh -o StrictHostKeyChecking=no ${SCRIPT_SSH_USER}@${SCRIPT_SSH_IP} <<'EOF'
                  set -euo pipefail
                  echo "🔍 Testing Flask App Endpoints..."

                  # Get LoadBalancer hostname directly
                  SERVICE_URL=\$(kubectl get svc jl-flask-service -n pyflask-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)

                  if [ -z "\$SERVICE_URL" ]; then
                    echo "❌ No Service URL found, LoadBalancer may still be pending"
                    exit 1
                  fi

                  echo "🌍 Testing against: http://\$SERVICE_URL"

                  # Test /api/hello
                  HELLO_RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" http://\$SERVICE_URL/api/hello || true)
                  # Test /api/health
                  HEALTH_RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" http://\$SERVICE_URL/api/health || true)

                  echo "HELLO endpoint status: \$HELLO_RESPONSE"
                  echo "HEALTH endpoint status: \$HEALTH_RESPONSE"

                  if [ "\$HELLO_RESPONSE" = "200" ] && [ "\$HEALTH_RESPONSE" = "200" ]; then
                    echo "🎉 Flask App endpoints are healthy!"
                  else
                    echo "❌ One or more endpoints failed"
                    exit 1
                  fi
EOF
                """
            }
        }
    }
}



    }





    post {
        success {
            echo "✅ Jenkins Pipeline Success - Build ${env.BUILD_NUMBER}"
        }
        failure {
            echo "❌ Jenkins Pipeline Failed - Build ${env.BUILD_NUMBER}"
        }
    }
}

