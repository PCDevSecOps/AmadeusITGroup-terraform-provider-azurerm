# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "a7e841c0-fc55-4831-b7ef-f7bb56c7c0e2"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}storageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
  tags = {
    yor_trace = "f410c65b-3718-47fe-a850-32ec38225686"
  }
}

resource "azurerm_storage_share" "example" {
  name                 = "${var.prefix}storageshare"
  storage_account_name = azurerm_storage_account.example.name
  quota                = 100
}
