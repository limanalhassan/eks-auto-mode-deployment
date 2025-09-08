variable "aws_profile" {
  type        = string
  default     = "terraform" # set to "" if you don't use profiles
  description = "Optional AWS CLI profile name used by local-exec"
}

locals {
  ingressclass_yaml = <<-YAML
  ---
  apiVersion: eks.amazonaws.com/v1
  kind: IngressClassParams
  metadata:
    name: alb
  spec:
    scheme: internet-facing
    group:
      name: opslevel-app
  ---
  apiVersion: networking.k8s.io/v1
  kind: IngressClass
  metadata:
    name: alb
    annotations:
      ingressclass.kubernetes.io/is-default-class: "true"
  spec:
    controller: eks.amazonaws.com/alb
    parameters:
      apiGroup: eks.amazonaws.com
      kind: IngressClassParams
      name: alb
  YAML
}

# Optional: a knob to force re-apply without editing YAML
variable "force_reapply" {
  type    = bool
  default = false
}

resource "null_resource" "apply_ingressclass" {
  depends_on = [module.eks]

  # All values needed at destroy-time must be available under self.*
  triggers = {
    manifest_b64 = base64encode(local.ingressclass_yaml)
    region       = var.region
    cluster_name = module.eks.cluster_name
    aws_profile  = var.aws_profile
    force        = var.force_reapply ? uuid() : ""
  }

  # CREATE: apply the manifest from stdin
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command = <<-EOT
      set -euo pipefail

      # Use a temp kubeconfig so we don't pollute global config
      KUBECFG="$(mktemp)"
      export KUBECONFIG="$KUBECFG"

      # Export profile only if provided (empty string means no-op)
      if [ -n "${self.triggers.aws_profile}" ]; then
        export AWS_PROFILE="${self.triggers.aws_profile}"
      fi

      aws eks update-kubeconfig \
        --name   "${self.triggers.cluster_name}" \
        --region "${self.triggers.region}" \
        --kubeconfig "$KUBECFG"

      # Apply from stdin
      echo "${self.triggers.manifest_b64}" | base64 -d | kubectl apply -f -

      rm -f "$KUBECFG"
    EOT
  }

  # DESTROY: delete the same manifest from stdin (no external refs)
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-lc"]
    command = <<-EOT
      set -euo pipefail

      KUBECFG="$(mktemp)"
      export KUBECONFIG="$KUBECFG"

      if [ -n "${self.triggers.aws_profile}" ]; then
        export AWS_PROFILE="${self.triggers.aws_profile}"
      fi

      aws eks update-kubeconfig \
        --name   "${self.triggers.cluster_name}" \
        --region "${self.triggers.region}" \
        --kubeconfig "$KUBECFG"

      # Best-effort delete from stdin
      echo "${self.triggers.manifest_b64}" | base64 -d | kubectl delete -f - --ignore-not-found || true

      rm -f "$KUBECFG"
    EOT
  }
}
