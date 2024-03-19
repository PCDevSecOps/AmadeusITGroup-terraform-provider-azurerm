# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "c2647183-1fd4-483b-9dfe-c42628019f05"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    yor_trace = "5b7228fa-4b0b-4e8f-a40d-bb894b1e0e20"
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
  allocation_method   = "Dynamic"
  tags = {
    yor_trace = "4695cb20-adb5-4a05-b3ff-951bb8b2df32"
  }
}

resource "azurerm_virtual_network_gateway" "example" {
  name                = "${var.prefix}-vnetgw"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  type     = "Vpn"
  vpn_type = "PolicyBased"
  sku      = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.example.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.example.id
  }
  tags = {
    yor_trace = "0ab5b4f4-1b77-4c96-8a94-e100020555a4"
  }
}
