variable "aws_region" {
  description = "AWS region where the EKS cluster is deployed"
  type        = string
  default     = "ap-northeast-2"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "demo-eks"
}
