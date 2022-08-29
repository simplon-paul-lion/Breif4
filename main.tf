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
  domain_name_label   = "dns-g3"
}

# Create VM


# Create bastion
resource "azurerm_bastion_host" "main" {
  name                = var.bastion
  location            = var.localisation
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet1.id
    public_ip_address_id = azurerm_public_ip.main.id
  }
}
