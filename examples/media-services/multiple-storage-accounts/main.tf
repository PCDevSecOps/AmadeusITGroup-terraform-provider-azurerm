# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "9f284097-f4a1-4167-8e3d-8018869daddf"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}stor1"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags = {
    yor_trace = "ff5526fd-57d5-4737-a851-3e49ba1dd040"
  }
}

resource "azurerm_storage_account" "example2" {
  name                     = "${var.prefix}stor2"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
    yor_trace   = "ce9d810b-6c17-4357-972d-ac3384a15324"
  }
}

resource "azurerm_media_services_account" "example" {
  name                = "${var.prefix}-mediasvc"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  storage_account {
    id         = azurerm_storage_account.example.id
    is_primary = true
  }

  storage_account {
    id         = azurerm_storage_account.example2.id
    is_primary = false
  }
  tags = {
    yor_trace = "d7dda277-a7e4-4220-895f-1d41e8d3aacb"
  }
}

output "rendered" {
  value = azurerm_media_services_account.example.id
}
