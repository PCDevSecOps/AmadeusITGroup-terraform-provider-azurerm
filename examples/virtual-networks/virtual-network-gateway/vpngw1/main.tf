# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "43c9e374-d20d-4eb1-89eb-514cb6eb85d9"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    yor_trace = "a10a1fec-3038-427f-99e9-bd8c8c605384"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    yor_trace = "5d7129f9-7140-41a7-b176-3262b509e6d4"
  }
}

resource "azurerm_virtual_network_gateway" "example" {
  name                = "${var.prefix}-vnetgw"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.example.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.example.id
  }
  tags = {
    yor_trace = "d260f4ef-a255-49a1-80f0-9ca41e1b2cd4"
  }
}
