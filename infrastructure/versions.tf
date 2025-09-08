terraform {
  required_version = ">= 1.3.2"

    backend "s3" {
    bucket         = "opslevel-terraform-statefile-388374893922"       
    key            = "eks/terraform.tfstate"
    region         = "ca-central-1"                   
    dynamodb_table = "opslevel-terraform-locks-388374893922"             
    encrypt        = true
    profile        = "terraform"                   
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.97.0"
    }
    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.11.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
  }
}