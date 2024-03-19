# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "7087c127-3a27-4394-98db-66e4deccedaf"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}storacc"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
    yor_trace   = "e9dfce87-e3aa-454e-9734-715f250c6825"
  }
}

resource "azurerm_media_services_account" "example" {
  name                = "${var.prefix}mediasvc"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  storage_account {
    id         = azurerm_storage_account.example.id
    is_primary = true
  }
  tags = {
    yor_trace = "4d745625-ef76-478e-ae13-ce16d80847c5"
  }
}

output "rendered" {
  value = azurerm_media_services_account.example.id
}
