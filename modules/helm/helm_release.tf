
resource "helm_release" "teamcity" {
  chart            = "${path.module}/charts/teamcity"
  create_namespace = true
  namespace        = var.service_name
  name             = var.service_name
  replace          = true
  wait             = var.helm_release_wait

  dynamic "set" {
    for_each = var.helm_settings
    content {
      name  = set.key
      value = set.value
    }
  }
  values = [yamlencode(var.helm_release_values)]

}

### Waiting because of team city pre configuration
resource "time_sleep" "wait_till_main_sever_starts" {
  depends_on      = [helm_release.teamcity]
  create_duration = "60s"
}

output "status" {
  value = helm_release.teamcity.status
}