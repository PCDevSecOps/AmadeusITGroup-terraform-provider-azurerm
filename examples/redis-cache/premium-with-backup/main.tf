# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "f9ff1f61-f26d-4917-bf69-529d85a2bb7b"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags = {
    yor_trace = "017f65ef-57ab-44c1-b10f-977312f0754b"
  }
}

# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "example" {
  name                = "${var.prefix}-cache"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  capacity            = 3
  family              = "P"
  sku_name            = "Premium"
  enable_non_ssl_port = false

  redis_configuration {
    rdb_backup_enabled            = true
    rdb_backup_frequency          = 60
    rdb_backup_max_snapshot_count = 1
    rdb_storage_connection_string = azurerm_storage_account.example.primary_blob_connection_string
  }
  tags = {
    yor_trace = "f1826c07-e1b2-4193-adef-7bc858c28eca"
  }
}
