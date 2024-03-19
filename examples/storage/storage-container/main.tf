# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "1b3654f7-bc58-47f0-a69a-8ea4537748f0"
  }
}

resource "azurerm_storage_account" "example" {
  name                = "${var.prefix}storageacct"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "LRS"
  enable_https_traffic_only       = true
  access_tier                     = "Hot"
  allow_nested_items_to_be_public = true
  tags = {
    yor_trace = "61106f53-4146-4c3b-b655-00d1fe443c20"
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "${var.prefix}storagecontainer"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "blob"
}

resource "azurerm_storage_account" "example2" {
  name                = "${var.prefix}storageacct2"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "LRS"
  enable_https_traffic_only       = true
  access_tier                     = "Hot"
  allow_nested_items_to_be_public = true
  tags = {
    yor_trace = "54fce9f8-8710-435c-98b7-081e10a0e1e3"
  }
}

resource "azurerm_storage_container" "example2" {
  name                  = "${var.prefix}storagecontainer2"
  storage_account_name  = azurerm_storage_account.example2.name
  container_access_type = "blob"
}
