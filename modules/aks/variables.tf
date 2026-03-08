variable "resource_group_name" {
  type = string
}

variable "resource_group_id" {
  type    = string
  default = ""
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "prefix" {
  type    = string
  default = ""
}

variable "suffix" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vnet_id" {
  type    = string
  default = ""
}

variable "aks_subnet_id" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.30.0"
}

variable "node_vm_size" {
  type    = string
  default = "Standard_DC2s_v3"
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 3
}

variable "log_analytics_workspace_id" {
  type    = string
  default = ""
}

variable "acr_id" {
  type    = string
  default = ""
}

variable "keyvault_id" {
  type    = string
  default = ""
}
