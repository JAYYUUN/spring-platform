output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "ecr_repo_url" { value = aws_ecr_repository.spring.repository_url }
output "github_actions_role_arn" { value = aws_iam_role.gha.arn }