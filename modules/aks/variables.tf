variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "environment" {
  type = string
}
variable "vnet_id" {
  type = string
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
  default = "Standard_B2s"
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
