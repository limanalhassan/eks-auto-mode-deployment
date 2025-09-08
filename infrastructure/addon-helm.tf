################################################################################
# ArgoCD Installation
################################################################################

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.0.1"

  values = [
    file("${path.module}/helm-valuesFiles/argocd.yaml")
  ]

  depends_on = [
    module.eks
  ]
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  namespace        = "kube-system"
  create_namespace = false
  version          = "3.12.2"

  values = [
    <<-EOT
    resources:
      limits:
        cpu: 100m
        memory: 200Mi
      requests:
        cpu: 50m
        memory: 100Mi
    EOT
  ]

  depends_on = [
    module.eks
  ]
}
