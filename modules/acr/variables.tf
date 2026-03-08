variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "environment" {
  type = string
}
variable "sku" {
  type    = string
  default = "Basic"
}

variable "suffix" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "suffix" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
