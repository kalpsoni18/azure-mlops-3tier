variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "environment" {
  type    = string
  default = ""
}
variable "prefix" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "cluster_name" {
  type    = string
  default = ""
}
variable "log_retention_days" {
  type    = number
  default = 7
}
variable "alert_email" {
  type    = string
  default = "alerts@example.com"
}
variable "enable_prometheus" {
  type    = bool
  default = true
}
variable "prometheus_retention" {
  type    = string
  default = "3d"
}
variable "prometheus_storage" {
  type    = string
  default = "5Gi"
}
variable "grafana_service_type" {
  type    = string
  default = "LoadBalancer"
}
variable "grafana_password" {
  type      = string
  sensitive = true
  default   = ""
}
variable "loki_retention" {
  type    = string
  default = "168h"
}
variable "loki_storage" {
  type    = string
  default = "5Gi"
}
