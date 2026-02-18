terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

#Provider는 Terraform이 외부 시스템과 상호작용하기 위한 일종의 드라이버로 이해할 수 있다.
#provider "kubernetes"는 Terraform이 Kubernetes API Server에 직접 접근하여,
#kubectl이 수행하는 것과 동일한 방식으로 Kubernetes 리소스(Deployment, Service 등)를 생성·관리할 수 있도록 한다.
#provider "helm"은 Terraform이 동일한 Kubernetes API에 접근하되,
#개별 리소스를 직접 다루는 대신 Helm Chart 기반의 배포 작업을 수행할 수 있도록 한다.
