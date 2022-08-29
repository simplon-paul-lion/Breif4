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
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDRBSlckGDaO56A0EEpSdi4fVE1dGyt14jb82CS2+McddNmqINOo53h4s/Lo6IPfoGpLegHXT1DRw9qb55XgVFDHhV9aTPvZJaKN3RbxlGrHbQZ2NuWRsU+KBxdKq4Qr94zBYgii/nojAmf56nYN0SMwBOGMdc1IbSybqiOFIZfFo18MATYJL4gInGu4BeyMQoN40tgddzYOx+94orM8FH8HuhhlkQCzvHTyz8Cov5jYyhV088H2hRgvn1E7bJHl8YjsT4wubUvf8ilDu6EzhMntQ1C61L65txyfxYp3E2O1ec8/0sLkW5rHpuyncUu7CbIFHkZ3qFhPeE1LLa7lmrmnu7N4BragVmX1oknR05jv/cucedRowwGnrcqKYiBQ7rVa9cWlY2ayCsmbDm7CwnOZoOebYpFO1RnKx/DJ8r/GgUysHaG9A1d3hdzloEwxbG2Osg2t5J8jf8zMNctb4MkbdZj9eIaHEsNyYHEtBpIZye+8Louf5m8EJGHCeKCksM= utilisateur@UTILISA-IUAPJVS"
  }

  admin_ssh_key {
    username   = var.admin2
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0agEe2jMnbMN3OX6bunAdpOoK7idzd5RajsTYcUuF+x1iqqUIXNqDmn6r518hl/NBzUFHshv5k/lasB5pUbHhS2MLpm9t56d5pHnSd3DfAieIggfrpk4RN5yKyKfYQ9DGNjvXgzXy2lSKnXG8fPrkhReJKGpuXe/se5UkpUtGyXQ4BQsAfaArzp0etWZF/KwyZ7ckfOsb7iHCicgoUjqyXbdpP+EooyhSsj6HRhINQ3OuSmtRhrYZLyYXbI/FuN5mtR/+2D4EOhEHFhlFWObJR7TUYRPOW/rCGF/2hNrqwdwWvSmHNg54wRGWmzmrOHZBgyIOAol20+2LUx53eaKObN8lx2chcHVGwEoLjEqbcTv2iQ/C0sTKrqKnvZyEqVftDS/3wMRt5kz4YwJmH7Bk+dZfzdoZX4lqtoYRZKljSmASn836TsH5SdAaNeD62BJ2Efgp3eKxr3ht5vZ9Ktf/aSxpayQ1rJXAmHYeueJI1p3c3v4cnJBpxwSG6cPNvGE= utilisateur@UTILISA-RDIKR2H"
  }

  admin_ssh_key {
    username   = var.admin3
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCno1QZ/tXQ+GT4To3zYouq3iMDhRrksttq00iQmQ5tyhQMKCkgQ3xKj5vu9eOyiBbe9pDclhF8T6Bb+qlvo8CoRJrUgthOb+bg8gfYeOipRYpk9IDYq2/Mlf261hXnmNwI5bZrvj/dD5Y+hj16JHma0B22xUp94BJRPj4vNvaWH1HuCFCdvHXga1XjvjggOl45lg+jDBirSl+nvnuFiiGfBfIa+ZFsYgTfapYIrbDi8PWk2shD7QuJvXiGDEd9dDCNcSe8Dslr8+M6CRRmnpPK8wJZiZrvnrPRw3tRuFLxR5V1ip3YMiuvfktw6Qg+RboJeoSw41qblwpH9bur0dt7vd8+/QiUbGp+x5UPn2PpRmOKqTMbRno3RTxaQFaemRzszn0vJIq4bH9NloVELo0GhIcadAmlIdAdLX63NoNJ2LCv6hZhBLJNtf5PZVjkWBYgbsxFPyu6bP532TAg3iwj40sFCXHXzqaTYSm1bzhCk+RGrdvcB760D1aoTXLEKqzoeocjpAuL6lI0JBvKMO+tEpS0M+cHPOTgPz5ZLEbjDdZHw4PzFyt0LaelPwXN8fl3hU89HH5E1iT/qPSCQTIwMnU9y+1fojMuXPYC7lb8bRFcUyAB5L35NOFhIiEZtd50NZsndAelJhXV9zQ9bj55MjYKQVgpl8RdbtpTUE8UgQ== rajac@LAPTOP-FI95FL62"
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
    destination_port_ranges    = ["22"]
    source_address_prefix      = azurerm_public_ip.main.ip_address
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