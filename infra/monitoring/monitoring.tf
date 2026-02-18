resource "kubernetes_namespace_v1" "monitoring" {
  metadata { name = "monitoring" }
}

resource "helm_release" "kube_prometheus_stack" {
  name      = "kube-prometheus-stack"
  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "58.3.1"

  atomic          = true
  cleanup_on_fail = true
  timeout         = 900

  values = [yamlencode({
    prometheus = {
      prometheusSpec = {
        retention          = "7d"
        scrapeInterval     = "30s"
        evaluationInterval = "30s"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes = ["ReadWriteOnce"]
              resources   = { requests = { storage = "20Gi" } }
            }
          }
        }
      }
    }

    alertmanager = { enabled = false }

    grafana = {
      enabled = true

      persistence = {
        enabled = true
        size    = "5Gi"
      }

      ingress = {
        enabled          = true
        ingressClassName = "alb"

        # ✅ 중요: ALB DNS로 접속하려면 host 조건을 없애야 안전함
        # (hosts 필드 자체를 생략하거나 빈 리스트로 두기)
        hosts = []

        path = "/"

        annotations = {
          "alb.ingress.kubernetes.io/scheme"       = "internal"
          "alb.ingress.kubernetes.io/target-type"  = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80}]"
        }
      }
    }
  })]

  depends_on = [kubernetes_namespace_v1.monitoring]
}
