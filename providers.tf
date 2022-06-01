provider "template" {}
provider "archive" {}
provider "kubernetes" {
  host                   = module.aws.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.aws.eks_certificate_authority)
  token                  = module.aws.eks_cluster_token
}

provider "helm" {
  kubernetes {
    host                   = module.aws.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.aws.eks_certificate_authority)
    token                  = module.aws.eks_cluster_token
  }
}

provider "aws" {
  region = var.region
}