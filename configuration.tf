locals {
  application_configuration_vars = {
    database_endpoint    = replace(module.aws.db_instance_endpoint, ":", "\\:")
    database_password    = module.aws.db_instance_password
    ingress_endpoint     = data.kubernetes_service.ingress.status[0].load_balancer[0].ingress[0].hostname
    s3_access_key_id     = module.aws.s3_access_user_key_id
    s3_access_key_secret = module.aws.s3_access_user_key_secret
    s3_bucket_name       = module.aws.s3_bucket_id
  }
}

resource "template_dir" "configure_tc" {
  source_dir      = "sources/teamcity/config_templates"
  destination_dir = "sources/teamcity/config"
  vars            = local.application_configuration_vars
}

data "archive_file" "tc_configuration" {
  type        = "zip"
  output_path = "sources/distr/tc-config.zip"
  source_dir  = "sources/teamcity/config"
  depends_on = [
    template_dir.configure_tc
  ]
}

locals {
  tc_helm_settings = {
    "ingress.enabled"    = true
    "storage.type"       = "aws"
    "storage.fsid"       = module.aws.efs_id
    "artifacts.arn"      = module.aws.s3_access_role_arn
    "artifacts.bucket"   = module.aws.s3_bucket_id
    "main.serverConfig"  = filebase64("sources/distr/tc-config.zip")
    "main.startupScript" = filebase64("sources/distr/tcinit.sh")
  }
  tc_helm_values = {
    ingress = {
      hosts = [
        {
          host = data.kubernetes_service.ingress.status[0].load_balancer[0].ingress[0].hostname
          paths = [
            {
              path     = "/"
              pathType = "ImplementationSpecific"
            }
          ]
        }
      ]
    }
  }
}