provider "aws" {
  region  = var.region
  profile = "terraform"
}
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "argocd" {
  core = true
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", "terraform"]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = [
        "eks", "get-token",
        "--cluster-name", module.eks.cluster_name,
        "--region", var.region
      ]
      env = { AWS_PROFILE = "terraform" }
    }
  }
}


