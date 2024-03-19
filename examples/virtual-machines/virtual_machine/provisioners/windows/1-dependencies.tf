# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  virtual_machine_name = "${var.prefix}-vm"
  admin_username       = "testadmin"
  admin_password       = "Password1234!"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "4a527807-11f6-463e-9ad0-1c8516b364e8"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "7eabf2d7-c5d8-4e10-8a03-9e789d00a9e4"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-publicip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  tags = {
    yor_trace = "cfc37141-2893-49d6-b4c0-ea5a8b1b0dd8"
  }
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
  tags = {
    yor_trace = "c59e1542-e4d8-4560-8e4a-e630d408cdc6"
  }
}
