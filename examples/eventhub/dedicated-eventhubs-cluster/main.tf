# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "c83e4463-d439-4f1c-ab88-1af1f03dc6e3"
  }
}

resource "azurerm_eventhub_cluster" "example" {
  name                = "${var.prefix}-ehcluster"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku_name            = "Dedicated_1"
  tags = {
    yor_trace = "a020b540-0f1d-4827-950e-6cd3cf716707"
  }
}

resource "azurerm_eventhub_namespace" "example" {
  name                 = "${var.prefix}-ehnamespace"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name
  sku                  = "Standard"
  dedicated_cluster_id = azurerm_eventhub_cluster.example.id
  tags = {
    yor_trace = "a6459e32-3685-4872-8fca-81fba1057ed9"
  }
}

resource "azurerm_eventhub" "example" {
  name                = "${var.prefix}-eventhub"
  resource_group_name = azurerm_resource_group.example.name
  namespace_name      = azurerm_eventhub_namespace.example.name
  partition_count     = 40
  message_retention   = 1
}
