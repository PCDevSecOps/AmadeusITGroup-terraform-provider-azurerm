# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "fd57bf03-4e15-4ce5-b0e7-01bfd768fac7"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "08692233-4969-48ae-9c15-b0bf2eae44a7"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    yor_trace = "ef171d75-4bd9-4b3d-b401-b6ab60c15350"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "P@ssw0rd1234!"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  tags = {
    yor_trace = "4604a406-918f-4830-9a6b-1f4895907f88"
  }
}

# azurerm_linux_virtual_machine.example has to be generalized in order to create the below image

resource "azurerm_image" "example" {
  name                      = "${var.prefix}image"
  location                  = azurerm_resource_group.example.location
  resource_group_name       = azurerm_resource_group.example.name
  source_virtual_machine_id = azurerm_linux_virtual_machine.example.id
  tags = {
    yor_trace = "6cf72e57-063c-43f9-9a55-8e4bf68b76e9"
  }
}
