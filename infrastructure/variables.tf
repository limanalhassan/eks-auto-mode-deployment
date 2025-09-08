variable "cluster_name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "opslevel-cluster-canada"
  type        = string
}

variable "name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "opslevel"
  type        = string
}

variable "region" {
  description = "region"
  default     = "ca-central-1"
  type        = string
}

variable "eks_cluster_version" {
  description = "EKS Cluster version"
  default     = "1.32"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR. This should be a valid private (RFC 1918) CIDR range"
  default     = "10.0.0.0/16"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare auth key"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "cname_labels" {
  description = "Cloudflare Zone name"
  type    = list(string)
  default = ["staging", "prod", "argocd", "dev"]
}

variable "cloudflare_proxied" {
  type    = bool
  default = true
}
