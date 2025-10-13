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
      name: liman-app
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
    is_windows   = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  }

  # CREATE: apply the manifest from stdin
  provisioner "local-exec" {
    interpreter = substr(pathexpand("~"), 0, 1) == "/" ? ["/bin/bash", "-lc"] : ["powershell.exe", "-Command"]
    command = substr(pathexpand("~"), 0, 1) == "/" ? (
      "set -euo pipefail; KUBECFG=$(mktemp); export KUBECONFIG=$KUBECFG; if [ -n '${self.triggers.aws_profile}' ]; then export AWS_PROFILE='${self.triggers.aws_profile}'; fi; aws eks update-kubeconfig --name '${self.triggers.cluster_name}' --region '${self.triggers.region}' --kubeconfig $KUBECFG; echo '${self.triggers.manifest_b64}' | base64 -d | kubectl apply -f -; rm -f $KUBECFG"
      ) : (
      "$ErrorActionPreference = 'Stop'; $KUBECFG = New-TemporaryFile | Select-Object -ExpandProperty FullName; $env:KUBECONFIG = $KUBECFG; if ('${self.triggers.aws_profile}') { $env:AWS_PROFILE = '${self.triggers.aws_profile}' }; aws eks update-kubeconfig --name '${self.triggers.cluster_name}' --region '${self.triggers.region}' --kubeconfig $KUBECFG; [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${self.triggers.manifest_b64}')) | kubectl apply -f -; Remove-Item -Path $KUBECFG -Force -ErrorAction SilentlyContinue"
    )
  }

  # DESTROY: delete the same manifest from stdin (no external refs)
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
