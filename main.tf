terraform {
  required_version = ">= 0.13"
  required_providers {
    helm       = ">= 1.0, < 3.0"
    kubernetes = ">= 2.11.0, < 3.0.0"
  }
}

### AWS infrastructure rollout
locals {
  name = var.name
  tags = {
    application = var.name
  }
}

module "aws" {
  source = "./modules/service_aws_cloud_resources"
  name   = var.name
  tags   = local.tags
}

### Preconfigured ingress chart
module "eks-ingress-nginx" {
  source = "lablabs/eks-ingress-nginx/aws"
  settings = {
    "controller.admissionWebhooks.enabled" = "false"
    "controller.replicaCount"              = "3"
  }
  version = "0.4.1"
  depends_on = [
    module.aws
  ]
}

data "kubernetes_service" "ingress" {
  metadata {
    namespace = "ingress-controller"
    name      = "ingress-nginx-controller"
  }
  depends_on = [
    module.eks-ingress-nginx
  ]
}

### Adding module to handle efs volume mount via pvc
module "efs_csi_driver" {
  source                           = "./modules/terraform-aws-eks-efs-csi-driver"
  cluster_name                     = module.aws.eks_cluster_id
  cluster_identity_oidc_issuer     = module.aws.eks_cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.aws.eks_oidc_provider_arn
  depends_on = [
    module.aws
  ]
}

module "teamcity_helm" {
  source                         = "./modules/helm"
  application_configuration_vars = local.application_configuration_vars
  service_name                   = local.name
  helm_settings                  = local.tc_helm_settings
  helm_release_values            = local.tc_helm_values
  depends_on = [
    module.efs_csi_driver,
    module.aws,
    data.kubernetes_service.ingress,
    data.archive_file.tc_configuration
  ]
}