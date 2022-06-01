variable "application_configuration_vars" {
  type = any
}

variable "service_name" {
  type = string
}

variable "helm_settings" {
  type = any
}

variable "helm_release_values" {
  type = any
}

variable "helm_release_wait" {
  type    = bool
  default = false
}

variable "helm_release_timeout" {
  type    = number
  default = 300
}