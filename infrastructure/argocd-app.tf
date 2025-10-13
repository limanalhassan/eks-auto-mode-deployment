locals {
  # Platform detection for cross-platform compatibility
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true

  applicationset_yaml = <<-YAML
  apiVersion: argoproj.io/v1alpha1
  kind: ApplicationSet
  metadata:
    name: liman-appset
    namespace: argocd
  spec:
    goTemplate: true
    generators:
    - list:
        elements:
        - env: prod
        - env: staging
        - env: dev
    template:
      metadata:
        name: '{{.env}}-liman'
        namespace: argocd
      spec:
        project: default
        source:
          repoURL: https://github.com/limanalhassan/eks-auto-mode-deployment.git
          targetRevision: HEAD
          path: application/{{.env}}
        destination:
          server: https://kubernetes.default.svc
          namespace: '{{.env}}'
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          syncOptions:
          - CreateNamespace=true
  YAML
}

# Optional: flip to true to force re-apply even if YAML unchanged
variable "force_reapply_appset" {
  type    = bool
  default = false
}

resource "null_resource" "apply_applicationset" {
  # ensure Argo CD (and its CRDs) exist, and your IngressClass is in
  depends_on = [
    helm_release.argocd,
    null_resource.apply_ingressclass
  ]

  triggers = {
    manifest_b64 = base64encode(local.applicationset_yaml)
    region       = var.region
    cluster_name = module.eks.cluster_name
    aws_profile  = var.aws_profile
    force        = var.force_reapply_appset ? uuid() : ""
    is_windows   = local.is_windows
  }

  # CREATE / UPDATE
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["powershell.exe", "-Command"] : ["/bin/bash", "-lc"]
    command = local.is_windows ? (
      "$ErrorActionPreference = 'Stop'; $KUBECFG = New-TemporaryFile | Select-Object -ExpandProperty FullName; $env:KUBECONFIG = $KUBECFG; if ('${self.triggers.aws_profile}') { $env:AWS_PROFILE = '${self.triggers.aws_profile}' }; aws eks update-kubeconfig --name '${self.triggers.cluster_name}' --region '${self.triggers.region}' --kubeconfig $KUBECFG; [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${self.triggers.manifest_b64}')) | kubectl apply -f -; Remove-Item -Path $KUBECFG -Force -ErrorAction SilentlyContinue"
      ) : (
      "set -euo pipefail; KUBECFG=$(mktemp); export KUBECONFIG=$KUBECFG; if [ -n '${self.triggers.aws_profile}' ]; then export AWS_PROFILE='${self.triggers.aws_profile}'; fi; aws eks update-kubeconfig --name '${self.triggers.cluster_name}' --region '${self.triggers.region}' --kubeconfig $KUBECFG; echo '${self.triggers.manifest_b64}' | base64 -d | kubectl apply -f -; rm -f $KUBECFG"
    )
  }

  # DESTROY
  provisioner "local-exec" {
    when        = destroy
    interpreter = self.triggers.is_windows ? ["powershell.exe", "-Command"] : ["/bin/bash", "-lc"]
    command = self.triggers.is_windows ? (
      "$ErrorActionPreference = 'Stop'; $KUBECFG = New-TemporaryFile | Select-Object -ExpandProperty FullName; $env:KUBECONFIG = $KUBECFG; if ('${self.triggers.aws_profile}') { $env:AWS_PROFILE = '${self.triggers.aws_profile}' }; aws eks update-kubeconfig --name '${self.triggers.cluster_name}' --region '${self.triggers.region}' --kubeconfig $KUBECFG; try { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${self.triggers.manifest_b64}')) | kubectl delete -f - --ignore-not-found } catch {}; Remove-Item -Path $KUBECFG -Force -ErrorAction SilentlyContinue"
      ) : (
      "set -euo pipefail; KUBECFG=$(mktemp); export KUBECONFIG=$KUBECFG; if [ -n '${self.triggers.aws_profile}' ]; then export AWS_PROFILE='${self.triggers.aws_profile}'; fi; aws eks update-kubeconfig --name '${self.triggers.cluster_name}' --region '${self.triggers.region}' --kubeconfig $KUBECFG; echo '${self.triggers.manifest_b64}' | base64 -d | kubectl delete -f - --ignore-not-found || true; rm -f $KUBECFG"
    )
  }
}
