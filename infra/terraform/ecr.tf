resource "aws_ecr_repository" "spring" {
  name = var.ecr_repo_name
  image_scanning_configuration { scan_on_push = true } # Docker 이미지를 ECR에 push할 때마다 AWS가 자동으로 OS 패키지 (glibc, openssl 등), 언어 런타임 라이브러리, 알려진 CVE(취약점 DB) 등에 대한 보안 스캔을 하도록 하는 설정
  tags = local.tags
}