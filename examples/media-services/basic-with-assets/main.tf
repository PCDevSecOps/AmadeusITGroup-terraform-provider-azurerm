# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "84600120-522f-4fb8-8231-a0bff5dbc8cf"
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
    yor_trace   = "74c640a1-fa7a-4faf-8154-bccbfaf47b18"
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
    yor_trace = "8b277022-c081-45bc-9eb5-f091e4dfaff2"
  }
}

resource "azurerm_media_asset" "example" {
  name                        = "Asset1"
  description                 = "Asset description"
  resource_group_name         = azurerm_resource_group.example.name
  media_services_account_name = azurerm_media_services_account.example.name
}

output "rendered" {
  value = azurerm_media_asset.example.id
}
