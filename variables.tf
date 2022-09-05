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

variable "subnet_vm" {
  default = "subnet_jenkins"
}

variable "ip_bastion" {
  default = "IP_publique_bastion"
}

variable "ip_vm" {
  default = "IP_publique_vm"
}

variable "bastion" {
  default = "bastion_brief4_g3"
}

variable "DNS_bastion"{
    default = "dns-g3"
}

variable "DNS_vm"{
    default = "dns-vm-g3"
}

variable "VM-nic"{
    default = "vm-nic"
}

variable "config_vm"{
    default = "ip_config_nic"
}

variable "VM_name"{
    default = "VM_g3"
}

variable "computerVM_name"{
    default = "VMg3"
}

variable "admin"{
    default = "admin"
}

variable "OSdisk_name"{
    default = "OSdisk"
}

variable "config_bastion"{
    default = "ip_config_bastion"
}

variable "NSG"{
    default = "NSG_group"
}

variable "VM_rule"{
    default = "SSH"
}

variable "VM_rule2"{
    default = "HTTP"
}

variable "server_name"{
    default = "g3server"
}

variable "mariadb_admin"{
    default = "adminmariadb"
}

variable "mariadb_password"{
    default = "helloPaulCeliaRaja3"
}

variable "mariadb_name"{
    default = "g3mariadb"
}

variable "mariadb_rule"{
    default = "mariadb_VM_rule"
}

variable "gateway_name"{
    default = "jenkinsproxy"
}

variable "gateway_config"{
    default = "gateway-ip-configuration"
}

variable "keyvault_name"{
    default = "keyvault-g3"
}

variable "storage_name"{
    default = "g3stockage"
}

variable "container_name"{
    default = "g3conteneur"
}
