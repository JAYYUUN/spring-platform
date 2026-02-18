# GitHub Actions Role을 EKS에 등록 (Access Entry)
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = "arn:aws:iam::586794453466:role/GitHubActions-ECR-EKS"
  type          = "STANDARD"
}

# 클러스터 관리자 권한 부여 (일단 되게)
resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.github_actions.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
