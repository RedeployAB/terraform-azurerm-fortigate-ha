variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "os_version" {
  type    = string
  default = "6.4.5"
}

variable "allowed_admin_ips" {
  type    = list(string)
  default = []
}
