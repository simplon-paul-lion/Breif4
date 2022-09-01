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
  default = "IP_publique_bastion"
}

variable "ippublique2" {
  default = "IP_publique_gateway"
}

variable "bastion" {
  default = "bastion_brief4_g3"
}

variable "DNS"{
    default = "dns-g3"
}

variable "DNS2"{
    default = "dns-gateway-g3"
}

variable "VM-nic"{
    default = "vm-nic"
}

variable "config_name"{
    default = "ip_config_nic"
}

variable "VM_name"{
    default = "VM_g3"
}

variable "computerVM_name"{
    default = "VMg3"
}

variable "admin"{
    default = "celia"
}

variable "admin2"{
    default = "paul"
}

variable "admin3"{
    default = "raja"
}

variable "OSdisk_name"{
    default = "OSdisk"
}

variable "config_name2"{
    default = "ip_config_bastion"
}

variable "NSG"{
    default = "NSG_group"
}

variable "VM_rule"{
    default = "VM_Bastion_rule"
}
