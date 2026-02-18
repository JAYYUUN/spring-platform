# Terraform이 Helm을 통해 Argo CD를 클러스터에 설치(또는 업그레이드)하겠다는 뜻

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.6.0" # 예시 (원하는 버전으로 고정)

  values = [
    file("${path.module}/argocd-values.yaml")
  ]
}

# Helm chart를 하나 설치할 건데, Terraform 내부 이름을 argocd로 부르겠다”는 의미
# Helm이 클러스터에 설치할 때 붙이는 릴리즈 이름
# Argo CD를 설치할 Kubernetes 네임스페이스
# 해당 네임스페이스가 없으면 Terraform(Helm)이 자동으로 생성해주겠다는 옵션
# Helm chart가 있는 “차트 저장소” 주소
# 그 저장소 안에서 어떤 차트를 설치할지 지정, 여기서는 Argo CD 차트를 선택
# 차트 버전을 고정(pinning)
# Helm 차트는 기본 설정값이 있는데, 이 파일은 그 기본값을 내가 원하는 값으로 덮어쓰기(커스터마이즈) 하기 위한 설정 파일

