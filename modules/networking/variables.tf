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
