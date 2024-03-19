# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "test" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "5c73b4a9-50e1-484c-a2a1-462742b88a39"
  }
}

resource "azurerm_key_vault" "test" {
  name                        = "${var.prefix}kv"
  location                    = azurerm_resource_group.test.location
  resource_group_name         = azurerm_resource_group.test.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  tags = {
    yor_trace = "005a32bd-3f63-4537-a9bd-d5484460e0e3"
  }
}
