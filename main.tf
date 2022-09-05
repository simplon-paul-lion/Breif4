###############
#   Général   #
###############

resource "azurerm_resource_group" "rg" {
  name     = var.group_label
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.group_label}-vnet"
  location            = var.location
  resource_group_name = var.group_label
  address_space       = ["10.0.0.0/16"]
}

##############
# VM Jenkins #
##############

resource "azurerm_network_security_group" "jenkinsnsg" {
  name                = "${var.group_label}-jenkins-nsg"
  location            = var.location
  resource_group_name = var.group_label

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "jenkins" {
  name                 = "subnet-jenkins"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.group_label
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "jenkins-nic" {
  name                = "jenkins-nic"
  location            = var.location
  resource_group_name = var.group_label

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jenkins.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.jenkins-nic.id
  network_security_group_id = azurerm_network_security_group.jenkinsnsg.id
}


resource "azurerm_linux_virtual_machine" "jenkins-vm" {
  name                  = "jenkins-vm"
  resource_group_name   = var.group_label
  location              = var.location
  network_interface_ids = [azurerm_network_interface.jenkins-nic.id, ]
  size                  = "Standard_A1_v2"
  admin_username        = "paul"


  admin_ssh_key {
    username   = "paul"
    public_key = file("C:/Users/utilisateur/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }
}

###########
# bastion #
###########
resource "azurerm_public_ip" "bastionpub" {
  name                = "bastion-pub"
  location            = var.location
  resource_group_name = var.group_label
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "bastionsub" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.group_label
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_bastion_host" "bastionG3B4" {
  name                = "${var.group_label}-bastion"
  location            = var.location
  resource_group_name = var.group_label

  tunneling_enabled = "true"
  sku               = "Standard"
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastionsub.id
    public_ip_address_id = azurerm_public_ip.bastionpub.id

  }
}

###########
# gateway #
###########

resource "azurerm_subnet" "subgtw" {
  name                 = "subgtw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

}

resource "azurerm_public_ip" "pubgtw" {
  name                = "pubgtw"
  location            = var.location
  resource_group_name = var.group_label
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label = "jenkinsg3"
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "jenkinsgtw" {

  name   = "jenkinsgtw"
  resource_group_name  = var.group_label
  location             = var.location
  sku {
    name ="Standard_V2"
    tier ="Standard_V2"
    capacity="2"
  }


  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pubgtw.id
  }

  http_listener {
    name                           = "listener-jenkins"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol ="Http"
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    ip_addresses =["10.0.1.10"]
  }

request_routing_rule {
  name = local.request_routing_rule_name
}


}





/*
resource "azurerm_application_gateway" "proxyjenkins" {
  name="proxy-jenkins"
  resource_group_name = var.group_label
  location = var.location
  
}*/
  
