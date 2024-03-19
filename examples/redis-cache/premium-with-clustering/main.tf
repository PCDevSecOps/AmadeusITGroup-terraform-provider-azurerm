# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "c938e817-1a94-4b12-a4f6-c4123fa526a4"
  }
}

# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "example" {
  name                = "${var.prefix}-cache"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  capacity            = 1
  family              = "P"
  sku_name            = "Premium"
  enable_non_ssl_port = false
  shard_count         = 3

  redis_configuration {
    maxmemory_reserved = 2
    maxmemory_delta    = 2
    maxmemory_policy   = "allkeys-lru"
  }
  tags = {
    yor_trace = "40a3b5cf-4afb-4b00-b3dc-73f9632f8924"
  }
}
