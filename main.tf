
# creation resouece group

resource "azurerm_resource_group" "rg" {
  name = var.resource_group_name
  location = var.location
  
} 

# creation vnet

resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_gr3
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name 
  address_space = ["10.1.0.0/16"]
  
}

# creation subnet vm

resource "azurerm_subnet" "subnet_vm" {
  name = var.subnet_vm
  resource_group_name = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.1.1.0/24"]
  
}

# creation subnet bastion

resource "azurerm_subnet" "subnet_bastion" {
  name = var.subnet_bastion
  resource_group_name = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.1.3.0/26"]
    
}

# creation subnet gateway

resource "azurerm_subnet" "subnet_gateway" {
  name = var.subnet_gateway
  resource_group_name = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.1.2.0/24"]

}



# creation network interface 

resource "azurerm_public_ip" "adresse_ip" {
  name                = "adresse_ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

}

resource "azurerm_public_ip" "adresse_ipvm" {
  name                = "adresse_ipvm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

}

resource "azurerm_public_ip" "adresse_ipgw" {
  name                = "adresse_ipgw"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "mymv" {
  name = var.interface_gr3
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name 

  ip_configuration {
    name = "my_gr3_configuration"
    subnet_id = azurerm_subnet.subnet_vm.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.1.1.10"
    public_ip_address_id = azurerm_public_ip.adresse_ipvm.id
  }
}


# creation viruel machine linux

data "template_file" "script" {
  template = "${file("cloud-init.yml")}"
}

data "template_cloudinit_config" "main" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.script.rendered}"
  }
}

resource "azurerm_linux_virtual_machine" "mymv" {
  name = "mv_gr3" 
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name 
  network_interface_ids = [azurerm_network_interface.mymv.id]
  size = "Standard_DS1_v2"


    os_disk {
      name = "myOsDisk"
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"

    }

    source_image_reference {
      publisher = "Canonical"
      offer = "UbuntuServer"
      sku = "16.04-LTS"
      version = "latest"
    }

    computer_name  = "myvm"
    admin_username  = "raja"
    disable_password_authentication = true
    custom_data = data.template_cloudinit_config.main.rendered

    admin_ssh_key {
    username   = "raja"
    public_key = file ("C:/Users/rajac/.ssh/id_rsa.pub")
  }

}

# creation bastion 

resource "azurerm_bastion_host" "vmbastion" {
  name = "vm.bastion"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name 
  tunneling_enabled = true
  sku = "Standard"
  

   ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet_bastion.id
    public_ip_address_id = azurerm_public_ip.adresse_ip.id

  }

}

resource "azurerm_network_security_group" "linuxVM-nsg" {
  name = "linuxVM-nsg"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule  {
    name = "ssh"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    source_address_prefix = "*"
    destination_port_ranges = ["22"]
    destination_address_prefix = "*"

  }  
  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "mymv" {
  network_interface_id = azurerm_network_interface.mymv.id
  network_security_group_id = azurerm_network_security_group.linuxVM-nsg.id

}

 # creation de la base de données Mariadb


resource "azurerm_mariadb_server" "servermdb" {
  name = "servermdb"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name

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

resource "azurerm_mariadb_database" "mariadb" {
  name = "mariadb"
  resource_group_name = azurerm_resource_group.rg.name 
  server_name = azurerm_mariadb_server.servermdb.name
  charset = "utf8" 
  collation = "utf8_general_ci"

}

resource "azurerm_mariadb_firewall_rule" "main" {
  name                = "firewall-rule"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mariadb_server.servermdb.name
  start_ip_address    = azurerm_public_ip.adresse_ipvm.ip_address
  end_ip_address      = azurerm_public_ip.adresse_ipvm.ip_address
}



locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-fpn"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-ficn"
}

resource "azurerm_application_gateway" "jenkinsproxy" {
  name                = "jenkinsproxy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet_gateway.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 8080
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.adresse_ipgw.id
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



resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgwj" {
  network_interface_id    = azurerm_network_interface.mymv.id
  ip_configuration_name   = "my_gr3_configuration"
  backend_address_pool_id = azurerm_application_gateway.jenkinsproxy.backend_address_pool[0].id 
}

## Create keyvault

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvaultgr3" {
  name                        = "keyvaultg3"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.client_id

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

resource "azurerm_storage_account" "storagegr3" {
  name                     = "storagegr3"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"

  }
}

