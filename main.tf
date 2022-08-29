# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.localisation
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  address_space       = ["10.1.0.0/16"]
}

# Create the 3 subnets
resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet_bastion
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = var.subnet_gateway
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_subnet" "subnet3" {
  name                 = var.subnet_appbdd
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.3.0/24"]
}

# Create the public IP
resource "azurerm_public_ip" "main" {
  name                = var.ippublique
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.DNS
}

# Create bastion
resource "azurerm_bastion_host" "main" {
  name                = var.bastion
  location            = var.localisation
  resource_group_name = var.resource_group_name
  tunneling_enabled   = true
  sku                 = "Standard"

  ip_configuration {
    name                 = var.config_name2
    subnet_id            = azurerm_subnet.subnet1.id
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

# Create VM
resource "azurerm_network_interface" "main" {
  name                = var.VM-nic
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = var.config_name
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = var.VM_name
  computer_name       = var.computerVM_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_A1_V2"
  admin_username      = var.admin
  network_interface_ids = [azurerm_network_interface.main.id,]

  admin_ssh_key {
    username   = var.admin
    public_key = file("C:/Users/utilisateur/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = var.OSdisk_name
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "main" {
  name                = var.NSG
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = var.VM_rule
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = [ "443","22","3389" ]
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_public_ip.main.ip_address
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}