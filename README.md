# 🚀 Python Flask App Deployment to AWS EKS using Jenkins CI/CD
[![Terraform](https://img.shields.io/badge/Terraform-1.9+-purple?logo=terraform)]()
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.33+-blue?logo=kubernetes)]()
[![Jenkins](https://img.shields.io/badge/Jenkins-Pipeline-red?logo=jenkins)]()
[![Docker](https://img.shields.io/badge/Docker-Build%20&%20Push-blue?logo=docker)]()
[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20ECR%20%7C%20S3-orange?logo=amazon-aws)]()
[![GitHub](https://img.shields.io/badge/GitHub-Repo%20%26%20CI-black?logo=github)]()

## 📌 Project Description
This project demonstrates a **CI/CD pipeline** to deploy a **Python Flask application** into **AWS EKS** using **Terraform, Docker, Kubernetes, and Jenkins**.

The pipeline provisions infra, containerizes the Flask app, pushes to **ECR**, and deploys to **EKS** with health checks.

---

## 🏃 Run Locally (Optional Debug)
```cmd
# Clone repo
git clone https://github.com/JOYSTON-LEWIS/Placement-Readiness-Test-HV.git
cd Placement-Readiness-Test-HV

# Install requirements
pip install -r requirements.txt

# Run Flask app locally
python app.py
```

## 🛠️ Technologies Used
- ☁️ **AWS** → EKS, ECR, S3, IAM, VPC  
- <img src="https://www.vectorlogo.zone/logos/terraformio/terraformio-icon.svg" width="20"/> **Terraform** → Infrastructure provisioning  
- 🐳 **Docker** → Flask app containerization  
- ☸️ **Kubernetes (kubectl)** → App deployment & service exposure  
- ⚙️ **Jenkins** → CI/CD automation  
- 💻 **GitHub** → Source code repository 

---

## ⚙️ Jenkins Credentials Setup

1️⃣ **AWS Credentials**  
- **ID**: `SECRETS_AWS_CONFIGURE_CREDENTIALS`  
- **Type**: AWS Credentials  
- **Access Key ID** / **Secret Access Key**  

2️⃣ **EC2 SSH Private Key**  
- **ID**: `SECRETS_EC2_SSH_PRIVATE_KEY`  
- **Type**: SSH Username with Private Key  
- **Username**: `ubuntu`  
- **Private Key**: PEM contents  

3️⃣ **GitHub Credentials**  
- **ID**: `GITHUB_CREDENTIALS`  
- **Type**: Username with Password  
- **Username**: `JOYSTON-LEWIS`  
- **Password / Token**: GitHub PAT  

4️⃣ **GitHub PAT (Secret Text)**  
- **ID**: `SECRETS_GITHUB_PAT_TOKEN`  
- **Type**: Secret Text  

---

## 📜 Jenkins Pipeline Stages

### 🔹 **Stage 1: Install & Verify Tools on EC2**
- Installs required tools (`curl`, `git`, `docker`, `python3`, `pip3`, `awscli`, `terraform`, `kubectl`, `eksctl`, `helm` if needed).  
- Verifies versions and checks installation success.

#### ✅ Test 1: Verify Tools
- Runs checks for each tool (`--version` or `command -v`).  
- Pipeline fails immediately if any tool is missing.

---

### 🔹 **Stage 2: Provision S3 & ECR**
- Creates **S3 bucket** for Terraform remote state (if not exist).  
- Creates **ECR repo** for Flask images (if not exist).

#### ✅ Test 2: Verify S3 & ECR
- Runs `aws s3 ls <bucket>` and `aws ecr describe-repositories --repository-names <repo>`.  
- Pipeline fails if bucket or repo missing.

---

### 🔹 **Stage 3: Git Pull, Dockerize & Push to ECR**
- Clones Flask repo (public/private)  
- Builds Docker image from `Dockerfile`  
- Pushes latest image to ECR  

#### ✅ Test 3: Verify Image in ECR
- Checks if image was created **1–2 mins ago** using `aws ecr describe-images`  
- Fails pipeline if no new image found  

---

### 🔹 **Stage 4: Kubernetes Deployment with LoadBalancer**
- Applies `deployment.yaml` and `service.yaml` in namespace `pyflask-app`  
- Service type `LoadBalancer` provisions AWS ELB  
- Saves ELB URL to `/home/ubuntu/kubernetes-deployment/service_url.txt`  

#### ✅ Test 4: Verify Flask App Endpoints
- Reads ELB URL  
- Hits:
  - `http://<elb-url>/api/hello`
  - `http://<elb-url>/api/health`  
- Passes if both return `200 OK`

---

## 🐳 Dockerfile
```dockerfile
FROM python:3.13.1-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

## <img src="https://www.vectorlogo.zone/logos/terraformio/terraformio-icon.svg" width="20"/> Terraform - main.tf
```tf
terraform {
  backend "s3" {
    bucket = "jl-pyflask-bucket"
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region     = "ap-south-1"
  access_key = "<YOUR-ACCESS-KEY-HERE>"
  secret_key = "<YOUR-SECRET-KEY-HERE>"
}

data "aws_vpc" "selected" { id = "vpc-0056d809452f9f8ea" }

data "aws_availability_zones" "available" {}

resource "aws_subnet" "eks_subnet" {
  count             = 2
  vpc_id            = data.aws_vpc.selected.id
  cidr_block        = element(["172.31.224.0/20", "172.31.240.0/20"], count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "eks-subnet-${count.index}" }
}

# -------------------
# Terraform-managed Cluster IAM Role
# -------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "jl_eks_pyflask_node_role"

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
  name = "jl_eks_pyflask_node_group_role"

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
  name     = "jl-pyflask-eks-cluster"
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
  node_group_name = "jl_eks_pyflask_node_group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.eks_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  lifecycle {
    create_before_destroy = true
  }
}
```

## ☸️ Kubernetes - deployment.yaml
```yaml
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
        image: 975050024946.dkr.ecr.ap-south-1.amazonaws.com/jl-python-flask-repository:jlpyflask
        imagePullPolicy: Always
        ports:
        - containerPort: 5000
```

## ☸️ Kubernetes - service.yaml
```yaml
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
```

## 📦 Deliverables
- ✅ **Terraform files** → Provision AWS infrastructure (S3, ECR, EKS, IAM, VPC, Subnets)  
- ✅ **Dockerfile** → Containerize the Flask app  
- ✅ **Jenkinsfile** → Full pipeline stages (located in repo root `./Jenkinsfile`)  
- ✅ **Kubernetes Manifests** → `deployment.yaml` and `service.yaml` for app deployment  
- ✅ **README.md** → Setup instructions and architecture documentation

### 📸 Screenshots:

![IMG_01](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_01.png)

![IMG_02](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_02.png)

![IMG_03](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_03.png)

![IMG_04](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_04.png)

![IMG_05](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_05.png)

![IMG_06](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_06.png)

![IMG_07](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_07.png)

![IMG_08](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_08.png)

![IMG_09](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_09.png)

![IMG_10](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_10.png)

![IMG_11](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_11.png)

![IMG_12](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_12.png)

![IMG_13](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_13.png)

![IMG_14](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_14.png)

![IMG_15](https://github.com/JOYSTON-LEWIS/My-Media-Repository/blob/main/PRT_Output_Screenshots/IMG_15.png)


---

### 3️⃣ **Future Improvements**

```markdown
- Add Blue-Green or Canary deployments with Helm  
- Integrate Prometheus + Grafana monitoring  
- Add Horizontal Pod Autoscaler (HPA) for Flask app  
- GitHub Actions alternative pipeline (multi-CI showcase)
```
  
## 📜 License
This project is licensed under the MIT License.

## 🤝 Contributing
Feel free to fork and improve the scripts! ⭐ If you find this project useful, please consider starring the repo—it really helps and supports my work! 😊

## 📧 Contact
For any queries, reach out via GitHub Issues.

---

## 🎯 **Thank you for reviewing this project! 🚀**

