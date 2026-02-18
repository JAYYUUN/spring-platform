#GitHub Actions용 Role + 최소권한
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "gha_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud" # GitHub Actions가 발급한 토큰의 aud 값을 검사하겠다 
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub" #GitHub Actions가 발급한 토큰의 subject 값을 검사하겠다 
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "gha" {
  name               = "GitHubActions-ECR-EKS"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "gha_policy" {
  # ECR Push
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:ListImages"
    ]
    resources = ["*"]
  }

  # kubeconfig 만들 때 필요
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [aws_eks_cluster.this.arn]
  }
}

resource "aws_iam_role_policy" "gha_inline" {
  role   = aws_iam_role.gha.id
  name   = "GitHubActions-ECR-EKS-Policy"
  policy = data.aws_iam_policy_document.gha_policy.json
}

