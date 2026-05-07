terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# -------------------------------------------------------------------
# Resource Group
# -------------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# -------------------------------------------------------------------
# Virtual Network
# -------------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = [
    "10.0.0.0/16"
  ]

  tags = var.tags
}

# -------------------------------------------------------------------
# Subnet
# -------------------------------------------------------------------

resource "azurerm_subnet" "subnet" {
  depends_on = [
    azurerm_virtual_network.vnet
  ]

  name                 = "subnet-${var.project_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = [
    "10.0.1.0/24"
  ]
}

# -------------------------------------------------------------------
# Public IP
# -------------------------------------------------------------------

resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = var.tags
}

# -------------------------------------------------------------------
# Network Security Group
# -------------------------------------------------------------------

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags

  security_rule {
    name      = "Allow-SSH"
    priority  = 1001
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range = "*"

    destination_port_range = "22"

    source_address_prefix = var.my_ip_address

    destination_address_prefix = "*"
  }
}

# -------------------------------------------------------------------
# Network Interface
# -------------------------------------------------------------------

resource "azurerm_network_interface" "nic" {
  depends_on = [
    azurerm_subnet.subnet,
    azurerm_public_ip.pip
  ]

  name                = "nic-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags

  ip_configuration {
    name = "internal"

    subnet_id = azurerm_subnet.subnet.id

    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

# -------------------------------------------------------------------
# NSG Association
# -------------------------------------------------------------------

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id = azurerm_network_interface.nic.id

  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -------------------------------------------------------------------
# Linux VM
# -------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "vm" {
  depends_on = [
    azurerm_network_interface.nic
  ]

  name                = "vm-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size = var.vm_size

  admin_username = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username = var.admin_username

    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    name = "osdisk-${var.project_name}"

    caching = "ReadWrite"

    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}