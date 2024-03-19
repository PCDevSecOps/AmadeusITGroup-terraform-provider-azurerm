# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "9b72eed4-abea-43b6-9438-7e5145ef2b97"
  }
}

resource "azurerm_container_registry" "example" {
  name                = "${var.prefix}registry"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  tags = {
    yor_trace = "08262ba4-d85b-4594-9908-4dbd4c187a8a"
  }
}
