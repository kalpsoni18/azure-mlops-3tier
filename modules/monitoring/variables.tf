variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "log_retention_days" { type = number
  default = 7 }
variable "alert_email" { type = string
  default = "alerts@example.com" }
variable "enable_prometheus" { type = bool
  default = true }
variable "prometheus_retention" { type = string
  default = "3d" }
variable "prometheus_storage" { type = string
  default = "5Gi" }
variable "grafana_password" {
  type        = string
  sensitive   = true
  description = "Grafana admin password. Pass module.keyvault.grafana_password — never hardcode."
}
variable "grafana_service_type" { type = string
  default = "LoadBalancer" }
variable "loki_retention" { type = string
  default = "168h"
  description = "Loki log retention (e.g. 168h=7d, 720h=30d)" }
variable "loki_storage" { type = string
  default = "5Gi" }
