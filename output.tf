output "external_address" {
  value       = "http://${local.application_configuration_vars.ingress_endpoint}"
  description = "url to access TeamCity main server"
}

output "sync_cluster_config" {
  value       = "aws eks update-kubeconfig --name ${local.name} --region ${var.region}"
  description = "awscli command to sync kubeconfig"
}

output "get_main_deployment_logs" {
  value       = "kubectl logs --namespace ${local.name} --all-containers deployment/${local.name}-main | grep 'Super user authentication token:'"
  description = "kubectl command to get super user token from logs"
}