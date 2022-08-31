
# Provides the Ressource Group to Logically contain resources 

resource "azurerm_resource_group" "rg" {
  name = var.resource_group_name
  location = var.location
  
} 

resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_gr3
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name 
  address_space = ["10.1.0.0/16"]
  
}

resource "azurerm_subnet" "subnet_vm" {
  name = var.subnet_vm
  resource_group_name = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.1.1.0/24"]
  
}

resource "azurerm_subnet" "subnet_bastion" {
  name = var.subnet_bastion
  resource_group_name = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.1.3.0/26"]
    
}

resource "azurerm_subnet" "subnet_gateway" {
  name = var.subnet_gateway
  resource_group_name = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.1.2.0/24"]

}

resource "azurerm_network_interface" "mymv" {
  name = var.interface_gr3
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name 

  ip_configuration {
    name = "my_gr3_configuration"
    subnet_id = azurerm_subnet.subnet_vm.id
    private_ip_address_allocation = "Dynamic"
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
    admin_username  = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
    username   = "azureuser"
    public_key = file ("C:/Users/rajac/.ssh/id_rsa.pub")
  }

}

resource "azurerm_public_ip" "adresse_ip" {
  name                = "adresse_ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

}
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


 
  






