# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "0fb7b9fa-4e1f-4cc4-9751-678cb9384ae3"
  }
}

resource "azurerm_recovery_services_vault" "example" {
  name                = "${var.prefix}-vault"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags = {
    yor_trace = "4e2cf3c6-1ae0-4bf0-bc41-f23e35cc42e6"
  }
}
