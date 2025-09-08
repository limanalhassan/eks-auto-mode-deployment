locals {
  applicationset_yaml = <<-YAML
  apiVersion: argoproj.io/v1alpha1
  kind: ApplicationSet
  metadata:
    name: opslevel-appset
    namespace: argocd
  spec:
    goTemplate: true
    generators:
    - list:
        elements:
        - env: prod
        - env: staging
    template:
      metadata:
        name: '{{.env}}-opslevel'
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
  }

  # CREATE / UPDATE
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command = <<-EOT
      set -euo pipefail
      KUBECFG="$(mktemp)"
      export KUBECONFIG="$KUBECFG"
      if [ -n "${self.triggers.aws_profile}" ]; then export AWS_PROFILE="${self.triggers.aws_profile}"; fi

      aws eks update-kubeconfig \
        --name   "${self.triggers.cluster_name}" \
        --region "${self.triggers.region}" \
        --kubeconfig "$KUBECFG"

      # Apply the ApplicationSet
      echo "${self.triggers.manifest_b64}" | base64 -d | kubectl apply -f -

      rm -f "$KUBECFG"
    EOT
  }

  # DESTROY
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-lc"]
    command = <<-EOT
      set -euo pipefail
      KUBECFG="$(mktemp)"
      export KUBECONFIG="$KUBECFG"
      if [ -n "${self.triggers.aws_profile}" ]; then export AWS_PROFILE="${self.triggers.aws_profile}"; fi

      aws eks update-kubeconfig \
        --name   "${self.triggers.cluster_name}" \
        --region "${self.triggers.region}" \
        --kubeconfig "$KUBECFG"

      # Best-effort delete
      echo "${self.triggers.manifest_b64}" | base64 -d | kubectl delete -f - --ignore-not-found || true

      rm -f "$KUBECFG"
    EOT
  }
}
