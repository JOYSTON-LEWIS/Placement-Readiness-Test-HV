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