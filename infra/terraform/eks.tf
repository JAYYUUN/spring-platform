#EKS Cluster + Managed Node Group

# EKS 클러스터 IAM Role
data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" { # role을 생성 
  name               = "${var.project}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json # role에 "aws_iam_policy_document" "eks_cluster_assume" 부착
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policies" { #aws_iam_role_policy_attachment : IAM Role ↔ IAM Policy를 연결(부착)하는 역할
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]) /*“AWS(EKS Control Plane)가 쿠버네티스의 의도를 AWS 리소스로 구현할 수 있도록 하는 정책*/
  role       = aws_iam_role.eks_cluster.name
  policy_arn = each.value
}

# 노드 IAM Role 
data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node" { #role 생성
  name               = "${var.project}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "eks_node_policies" { #aws_iam_role_policy_attachment : IAM Role ↔ IAM Policy를 연결(부착)하는 역할
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]) /*EKS 노드가 “클러스터에 붙어서, 네트워크를 받고, 이미지를 내려받아 Pod를 실행하기 위해 반드시 필요한 최소 권한 세트*/
  role       = aws_iam_role.eks_node.name
  policy_arn = each.value
}

# 보안그룹 (최소)
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project}-eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.this.id
  tags        = local.tags
}

resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id) # 클러스터가 ‘통신하고 리소스를 배치할 수 있는 네트워크 범위’를 정하는 설정
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_public_access  = true  # EKS API Server(kube-apiserver)를 인터넷에 공개
    endpoint_private_access = false # EKS API Server(kube-apiserver)를 VPC 내부에서 접근
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policies]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = local.tags

}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name # 이 노드 그룹이 어느 EKS 클러스터 소속인지
  node_group_name = "${var.project}-ng"
  node_role_arn   = aws_iam_role.eks_node.arn # 노드(EC2)가 사용할 IAM Role
  subnet_ids      = aws_subnet.private[*].id  # 노드를 어디에 띄울지

  instance_types = var.node_instance_types

  scaling_config {                  # 노드 개수 자동 조절 설정 
    desired_size = var.desired_size # 평소에 유지할 노드 수
    min_size     = var.min_size     # 최소 보장 노드 수
    max_size     = var.max_size     # 최대 늘어날 수 있는 노드 수
  }

  depends_on = [aws_iam_role_policy_attachment.eks_node_policies]
  tags       = local.tags
}