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


#Terraform에서 EKS 클러스터 내부에 리소스를 적용하려면, 먼저 해당 클러스터에 접속할 수 있는 설정이 필요하다. 
#이를 위해 Terraform은 AWS에 이미 생성된 EKS 클러스터의 정보를 조회하여 API 서버 주소와 인증서를 가져오고, 동시에 IAM 기반 인증을 통해 Kubernetes API에 접근할 수 있는 임시 토큰을 생성한다. 
#이 정보들은 Kubernetes provider와 Helm provider에 전달되어, Terraform이 EKS 클러스터의 Kubernetes API로 정상적으로 요청을 보낼 수 있게 된다. 
