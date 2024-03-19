# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "1031d04a-a0a3-4747-8d08-1d414dd0c16c"
  }
}

resource "azurerm_virtual_wan" "example" {
  name                = "${var.prefix}-virtualwan"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tags = {
    yor_trace = "1ae6278e-88b7-4c17-a994-2c70d775c63b"
  }
}

resource "azurerm_virtual_hub" "example" {
  name                = "${var.prefix}-virtualhub"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_prefix      = "10.0.1.0/24"
  virtual_wan_id      = azurerm_virtual_wan.example.id
  tags = {
    yor_trace = "3213f908-f4a4-43b9-9ef4-a031d15e20e9"
  }
}
