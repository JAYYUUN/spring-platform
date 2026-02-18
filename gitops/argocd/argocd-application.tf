resource "time_sleep" "wait_for_argocd_crds" {
  depends_on      = [helm_release.argocd]
  create_duration = "60s"
}
# Argo CD(또는 최소한 CRD)가 먼저 설치되어야 Application 리소스를 만들 수 있다.
# Helm 설치 직후 CRD ready까지 대기

resource "kubernetes_manifest" "spring_app" {
  depends_on = [time_sleep.wait_for_argocd_crds]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "spring-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/JAYYUUN/spring-platform"
        targetRevision = "main"
        path           = "gitops/argocd"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }

}

# Terraform이 쿠버네티스 리소스 하나를 생성하겠다는 선언
# “이건 Argo CD의 Application 리소스다”라고 명확히 선언
# Argo CD가 설치된 argocd 네임스페이스 안에 spring-app이라는 이름의 Application을 하나 만든다
# Argo CD 내부의 논리적 묶음(Project) 중 default에 속하게 함
# 배포의 기준은 Git, 이 리포지토리의 main 브랜치, 그 중 k8s/ 디렉토리를 배포 소스로 삼겠다
# 이 Git 내용을 현재 클러스터의 default 네임스페이스에 적용
# 자동 동기화
# prune = true : Git에서 삭제되면 클러스터에서도 삭제
# selfHeal = true : 수동 변경이 생기면 Git 상태로 되돌림
# Argo CD(Helm 설치)가 먼저 설치된 뒤에 이 Application을 만들도록 순서 보장