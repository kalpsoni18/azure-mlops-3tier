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

variable "suffix" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "tenant_id" {
  type    = string
  default = ""
}

variable "aks_identity_id" {
  type    = string
  default = ""
}

variable "aks_csi_identity_id" {
  type    = string
  default = ""
}

variable "aks_kubelet_identity_id" {
  type    = string
  default = ""
}

variable "db_username" {
  type    = string
  default = "pgadmin"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_fqdn" {
  type    = string
  default = ""
}
