terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = "arn:aws:eks:ap-northeast-2:586794453466:cluster/demo-eks"
}

provider "helm" {
  kubernetes = {
    config_path    = pathexpand("~/.kube/config")
    config_context = "arn:aws:eks:ap-northeast-2:586794453466:cluster/demo-eks"
  }
}
