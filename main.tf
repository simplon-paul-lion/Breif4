# connexion vm : az network bastion ssh -n "bastion_brief4_g3" --resource-group "brief4_g3" --target-resource-id "/subscriptions/a1f74e2d-ec58-4f9a-a112-088e3469febb/resourceGroups/brief4_g3/providers/Microsoft.Compute/virtualMachines/VM_g3" --auth-type "ssh-key" --username "celia" --ssh-key "C:/Users/utilisateur/.ssh/id_rsa"

## Create a resource group

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.localisation
}

## Create a virtual network within the resource group

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  location = var.localisation
  address_space       = ["10.1.0.0/16"]
}

## Create the 3 subnets

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

## Create the public IP for bastion

resource "azurerm_public_ip" "main" {
  name                = var.ippublique
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.DNS
}

## Create the public IP for gateway

resource "azurerm_public_ip" "gateway" {
  name                = var.ippublique2
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.DNS2
}

## Create bastion

resource "azurerm_bastion_host" "main" {
  name                = var.bastion
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name
  tunneling_enabled   = true
  sku                 = "Standard"

  ip_configuration {
    name                 = var.config_name2
    subnet_id            = azurerm_subnet.subnet1.id
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

## Create VM

resource "azurerm_network_interface" "main" {
  name                = var.VM-nic
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = var.config_name
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = var.VM_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.localisation
  size                = "Standard_A1_V2"
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
  
  computer_name       = var.computerVM_name
  disable_password_authentication = true
  admin_username = var.admin
}

## Create NSG

resource "azurerm_network_security_group" "main" {
  name                = var.NSG
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = var.VM_rule
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

## Create mariadb database

resource "azurerm_mariadb_server" "main" {
  name = "g3mariadb"
  location = var.localisation
  resource_group_name = azurerm_resource_group.main.name

  administrator_login = "adminmariadb"
  administrator_login_password = "helloPaulCeliaRaja3"

  sku_name = "B_Gen5_2"
  storage_mb = 5120
  version = "10.2"

  auto_grow_enabled = true
  backup_retention_days = 7 
  geo_redundant_backup_enabled = false 
  public_network_access_enabled = true
  ssl_enforcement_enabled = true
}

resource "azurerm_mariadb_database" "main" {
  name = "mariadb"
  resource_group_name = azurerm_resource_group.main.name 
  server_name = azurerm_mariadb_server.main.name
  charset = "utf8" 
  collation = "utf8_general_ci"

}

## Create gateway

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.main.name}-beap"
  http_setting_name              = "${azurerm_virtual_network.main.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.main.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.main.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.main.name}-rdrcfg"
  frontend_port_name             = "${azurerm_virtual_network.main.name}-fpn"
  frontend_ip_configuration_name = "${azurerm_virtual_network.main.name}-ficn"
}

resource "azurerm_application_gateway" "main" {
  name                = "jenkinsproxy"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.localisation

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet2.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority = 100
  }
}

## Create keyvault

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                        = "keyvault-g3"
  location                    = var.localisation
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_storage_account" "main" {
  name                     = "g3stockage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.localisation
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "main" {
  name                  = "g3conteneur"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
