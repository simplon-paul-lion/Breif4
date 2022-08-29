variable "resource_group_name" {
  default = "brief4_g3"
}

variable "localisation" {
  default = "francecentral"
}

variable "vnet_name" {
  default = "vnet_brief4_g3"
}

variable "subnet_bastion" {
  default = "AzureBastionSubnet"
}

variable "subnet_gateway" {
  default = "subnet_gateway"
}

variable "subnet_appbdd" {
  default = "subnet_jenkins"
}

variable "ippublique" {
  default = "IP_publique"
}

variable "bastion" {
  default = "bastion_brief4_g3"
}
