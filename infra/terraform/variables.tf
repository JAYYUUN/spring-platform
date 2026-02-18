variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project" {
  type    = string
  default = "spring-demo"
}

variable "eks_cluster_name" {
  type    = string
  default = "demo-eks"
}

variable "eks_version" {
  type    = string
  default = "1.29"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 3
}

# GitHub Actions OIDC 제한용(권장)
variable "github_owner" {
  type    = string
  default = "JAYYUUN"
}

variable "github_repo" {
  type    = string
  default = "spring-demo-eks2"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "ecr_repo_name" {
  type    = string
  default = "my-spring-app"
}
