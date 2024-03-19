# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

locals {
  virtual_machine_name = "${var.prefix}vm"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "ac732f3a-babb-467c-b5a7-ec82cdabc06e"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  address_space       = ["172.16.0.0/16"]
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tags = {
    yor_trace = "08136224-620d-4af5-a275-dc977eac9a5c"
  }
}

resource "azurerm_subnet" "external" {
  name                 = "external"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["172.16.1.0/24"]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["172.16.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
  tags = {
    yor_trace = "8fc97da0-b10c-4dcc-91ab-b389d5fd189d"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "allow_SSH"
    description                = "Allow SSH access"
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
    name                       = "allow_RDP"
    description                = "Allow RDP access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    yor_trace = "c5709e3b-2238-4dcf-b31f-2c093af0b2fc"
  }
}

resource "azurerm_network_interface" "external" {
  name                      = "${var.prefix}-ext-nic"
  location                  = azurerm_resource_group.example.location
  resource_group_name       = azurerm_resource_group.example.name
  network_security_group_id = azurerm_network_security_group.example.id

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
  tags = {
    yor_trace = "b0ffb66d-6668-4f71-b611-56f3c47a3e49"
  }
}

resource "azurerm_network_interface" "internal" {
  name                = "${var.prefix}-int-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    yor_trace = "d49eb339-bf0e-430c-a67d-211ea1dd5e86"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                          = "${var.prefix}-vm"
  location                      = azurerm_resource_group.example.location
  resource_group_name           = azurerm_resource_group.example.name
  primary_network_interface_id  = azurerm_network_interface.external.id
  network_interface_ids         = ["${azurerm_network_interface.external.id}", "${azurerm_network_interface.internal.id}"]
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.virtual_machine_name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = local.virtual_machine_name
    admin_username = "myadmin"
    admin_password = "Passwword1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    yor_trace = "e9c8e69a-2c15-4cb1-aeba-af5e5639194e"
  }
}
