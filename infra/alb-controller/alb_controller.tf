# Terraform의 locals 블록은 구성 전반에서 반복 사용되는 고정 값을 정의하기 위한 내부 변수로, 설계적으로 변경되지 않아야 하는 값을 일관되게 참조하기 위해 사용된다.

locals {
  namespace = "kube-system"
  sa_name   = "aws-load-balancer-controller"
}

# EKS OIDC issuer의 TLS fingerprint 얻기
data "tls_certificate" "eks_oidc" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# (중요) 이미 OIDC Provider가 AWS IAM에 만들어져 있으면 이 리소스는 "import" 해야 함
resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
}

# EKS 클러스터의 OIDC issuer가 서명해 발급한 ServiceAccount 토큰(WebIdentity) 중에서도, 특정 네임스페이스의 특정 ServiceAccount(sub)에서 나온 토큰만 이 IAM Role을 sts:AssumeRoleWithWebIdentity로 Assume할 수 있도록 하는 신뢰 정책을 만든다.
data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.namespace}:${local.sa_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.eks_cluster_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

# ✅ 최소권한 정책(공식 권장 정책을 그대로 넣는 게 베스트)
# 길어서 "대표 핵심만" 넣으면 실제 운영에서 권한 부족 날 수 있으니,
# 아래는 컨트롤러 공식 정책을 '그대로' 넣는 형태로 사용 권장.
# (정식 정책 JSON은 AWS Load Balancer Controller docs의 IAM policy를 복붙해 사용)

resource "aws_iam_policy" "alb_controller_policy" {
  name   = "${var.eks_cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/alb_iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

# Helm으로 AWS Load Balancer Controller 설치
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = local.namespace
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  # 필요하면 고정 버전 (예: 1.7.2)
  # version = "1.7.2"

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  # IRSA: ServiceAccount 생성 + role-arn 주입
  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = local.sa_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }
}

# Terraform이 Helm을 통해 AWS Load Balancer Controller를 설치하면서,
# “이 클러스터/리전/VPC에서 동작하고, 이 ServiceAccount는 이 IAM Role(IRSA)을 써라”라고 알려주는 설정이다.

