variable "environment" {
  type = string
}

variable "project" {
  type    = string
  default = "mlops3tier"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "vnet_address_space" {
  type = string
}

variable "public_subnet_prefix" {
  type = string
}

variable "private_subnet_prefix" {
  type = string
}

variable "database_subnet_prefix" {
  type = string
}

variable "aks_subnet_prefix" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.30.0"
}

variable "aks_node_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "aks_node_min" {
  type    = number
  default = 1
}

variable "aks_node_max" {
  type    = number
  default = 2
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}

variable "db_username" {
  type    = string
  default = "pgadmin"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_sku" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  type    = number
  default = 32768
}

variable "db_backup_days" {
  type    = number
  default = 7
}

variable "db_geo_backup" {
  type    = bool
  default = false
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

variable "loki_retention" {
  type    = string
  default = "168h"
}

variable "loki_storage" {
  type    = string
  default = "5Gi"
}
