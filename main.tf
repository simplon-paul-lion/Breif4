# connexion vm : az network bastion ssh -n "bastion_brief4_g3" --resource-group "brief4_g3" --target-resource-id "/subscriptions/a1f74e2d-ec58-4f9a-a112-088e3469febb/resourceGroups/brief4_g3/providers/Microsoft.Compute/virtualMachines/VM_g3" --auth-type "ssh-key" --username "celia" --ssh-key "C:/Users/utilisateur/.ssh/id_rsa"

## Create a resource group

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.localisation
}

## Create a virtual network within the resource group

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.localisation
  address_space       = ["10.1.0.0/16"]
}

## Create subnet VM

resource "azurerm_subnet" "subnet_vm" {
  name                 = var.subnet_vm
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Create subnet bastion

resource "azurerm_subnet" "subnet_bastion" {
  name                 = var.subnet_bastion
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Create subnet gateway

resource "azurerm_subnet" "subnet_gateway" {
  name                 = var.subnet_gateway
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.3.0/24"]
}

## Create the public IP for bastion

resource "azurerm_public_ip" "adresse_bastion" {
  name                = var.ip_bastion
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.DNS_bastion
}

## Create the public IP for VM

resource "azurerm_public_ip" "adresse_vm" {
  name                = var.ip_vm
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.DNS_vm
}

## Create bastion

resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name
  tunneling_enabled   = true
  sku                 = "Standard"

  ip_configuration {
    name                 = var.config_bastion
    subnet_id            = azurerm_subnet.subnet_bastion.id
    public_ip_address_id = azurerm_public_ip.adresse_bastion.id
  }
}

## Create VM

resource "azurerm_network_interface" "vm" {
  name                = var.VM-nic
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = var.config_vm
    subnet_id                     = azurerm_subnet.subnet_vm.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.10"
  }
}

data "template_file" "script" {
  template = "${file("cloud-init.yml")}"
}

data "template_cloudinit_config" "cloudinit" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.script.rendered}"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.VM_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.localisation
  size                = "Standard_A1_v2"
  network_interface_ids = [azurerm_network_interface.vm.id]

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
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }
  
  computer_name                   = var.computerVM_name
  disable_password_authentication = true
  admin_username                  = var.admin
  custom_data                     = data.template_cloudinit_config.cloudinit.rendered
}

## Create NSG

resource "azurerm_network_security_group" "vm" {
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

   security_rule {
    name                       = var.VM_rule2
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = var.VM_rule3
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

## Create mariadb database

resource "azurerm_mariadb_server" "mariadb" {
  name = var.server_name
  location = var.localisation
  resource_group_name = azurerm_resource_group.main.name

  administrator_login = var.mariadb_admin
  administrator_login_password = var.mariadb_password

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
  name = var.mariadb_name
  resource_group_name = azurerm_resource_group.main.name 
  server_name = azurerm_mariadb_server.mariadb.name
  charset = "utf8" 
  collation = "utf8_general_ci"

}

resource "azurerm_mariadb_firewall_rule" "mariadb" {
  name                = var.mariadb_rule
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mariadb_server.mariadb.name
  start_ip_address    = azurerm_public_ip.adresse_vm.ip_address
  end_ip_address      = azurerm_public_ip.adresse_vm.ip_address
}

## Create gateway

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-fpn"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-ficn"
}

resource "azurerm_application_gateway" "gateway" {
  name                = var.gateway_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.localisation

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = var.gateway_config
    subnet_id = azurerm_subnet.subnet_gateway.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 8080
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.adresse_vm.id
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

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "gateway" {
  network_interface_id    = azurerm_network_interface.vm.id
  ip_configuration_name   = var.config_vm
  backend_address_pool_id = tolist(azurerm_application_gateway.gateway.backend_address_pool).0.id
}

## Create keyvault

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                        = var.keyvault_name
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
      "Get", "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Import", "List", "Purge", "Recover", "Restore", "Sign", "Update", "UnwrapKey", "Verify", "WrapKey"
    ]

    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore","Set"
    ]

    storage_permissions = [
      "Get", "Backup", "Delete", "DeleteSAS", "GetSAS", "List","ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
    ]
  }
}

resource "azurerm_storage_account" "keyvault" {
  name                     = var.storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.localisation
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "keyvault" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.keyvault.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "keyvault" {
  name                   = "/.well-known/acme-challenge"
  storage_account_name   = azurerm_storage_account.keyvault.name
  storage_container_name = azurerm_storage_container.keyvault.name
  type                   = "Block"
  source                 = "test.txt"
}

resource "azurerm_log_analytics_workspace" "monitor" {
  name                = var.log_name
  location            = var.localisation
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# resource "azurerm_application_insights" "monitor" {
#   name                = var.app_insight_name
#   location            = var.localisation
#   resource_group_name = azurerm_resource_group.main.name
#   application_type    = "web"
# }

resource "azurerm_monitor_action_group" "monitor" {
  name                = var.action_group_name
  resource_group_name = azurerm_resource_group.main.name
  short_name          = var.action_group_short_name

  email_receiver {
    name                    = var.devops1
    email_address           = var.email_devops1
    use_common_alert_schema = true
  }

    email_receiver {
    name                    = var.devops2
    email_address           = var.email_devops2
    use_common_alert_schema = true
  }

    email_receiver {
    name                    = var.devops3
    email_address           = var.email_devops3
    use_common_alert_schema = true
  }

  #   email_receiver {
  #   name                    = var.formateur1
  #   email_address           = var.email_formateur1
  #   use_common_alert_schema = true
  # }

  #   email_receiver {
  #   name                    = var.formateur2
  #   email_address           = var.email_formateur2
  #   use_common_alert_schema = true
  # }
}

resource "azurerm_monitor_metric_alert" "vm" {
  name                = var.alert_name_vm
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "CPU > 90%"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.monitor.id
  }
}

resource "azurerm_monitor_metric_alert" "mariadb" {
  name                = var.alert_name_db
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_mariadb_server.mariadb.id]
  description         = "Espace disponible sur la base de données < 10%"

  criteria {
    metric_namespace = "Microsoft.DBforMariaDB/servers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.monitor.id
  }
}

resource "azurerm_monitor_metric_alert" "gateway" {
  name                = var.alert_name_gateway
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_gateway.gateway.id]
  description         = "Application gateway indisponible"
  # if number of backend servers that Application Gateway is unable to probe successfully > 0

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.monitor.id
  }
}

# resource "azurerm_monitor_metric_alert" "gateway" {
#   name                = var.alert_name_gateway
#   resource_group_name = azurerm_resource_group.main.name
#   scopes              = [azurerm_application_gateway.gateway.id]
#   description         = "Date d’expiration du certificat TLS < 7 jours"

#   criteria {
#     metric_namespace = ""
#     metric_name      = ""
#     aggregation      = "Total"
#     operator         = "LesserThan"
#     threshold        = 7
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.monitor.id
#   }
# }