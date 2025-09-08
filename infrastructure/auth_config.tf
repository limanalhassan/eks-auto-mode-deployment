module "eks_auth" {
  source = "aidanmelen/eks-auth/aws"
  eks    = module.eks

    map_roles = [
      {
        rolearn  = "arn:aws:iam::021891590254:role/limanEKS-cluster-us-eks-auto-20250514195758006800000001"
        username = "limanEKS-cluster-us-eks-auto-20250514195758006800000001"
        groups   = ["system:masters"]
      },
    ]

  map_users = [
    {
      userarn  = "arn:aws:iam::021891590254:user/terraform"
      username = "terraform"
      groups   = ["system:masters"]
    }
  ]

  depends_on = [
    module.eks
  ]
}
