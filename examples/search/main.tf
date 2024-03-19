# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "aec5df7d-2ea0-4569-9029-205426cd5989"
  }
}

resource "azurerm_search_service" "example" {
  name                = "${var.prefix}-search"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "standard"
  replica_count       = "1"
  partition_count     = "1"
  tags = {
    yor_trace = "644a5d04-0ce2-40a4-89a6-e375a5d9b4ec"
  }
}
