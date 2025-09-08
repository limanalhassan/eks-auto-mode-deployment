# Lookup the ALB by name (note: identifier can't contain dashes)
data "aws_lb" "opslevel_alb" {
  name = "opslevel-app-alb"

  depends_on = [helm_release.argocd] 
}

