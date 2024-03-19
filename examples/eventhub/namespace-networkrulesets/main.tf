# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "c8bf5ad0-2249-4fdc-a2ea-f47bedfffc45"
  }
}

resource "azurerm_virtual_network" "example1" {
  name                = "${var.prefix}-vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "9579ef75-b94d-42f2-a5dc-d241026278cf"
  }
}

resource "azurerm_subnet" "example1" {
  name                 = "${var.prefix}-subnet1"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example1.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.EventHub"]
}

resource "azurerm_virtual_network" "example2" {
  name                = "${var.prefix}-vnet2"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "69a5b204-4b5e-4ab4-af03-32feedef7205"
  }
}

resource "azurerm_subnet" "example2" {
  name                 = "${var.prefix}-subnet2"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example2.name
  address_prefixes     = ["10.1.1.0/24"]
  service_endpoints    = ["Microsoft.EventHub"]
}

resource "azurerm_eventhub_namespace" "example" {
  name                = "${var.prefix}-ehnamespace"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  capacity            = "2"

  network_rulesets {
    default_action = "Deny"

    virtual_network_rule {
      subnet_id                                       = azurerm_subnet.example1.id
      ignore_missing_virtual_network_service_endpoint = false
    }

    virtual_network_rule {
      subnet_id = azurerm_subnet.example2.id
    }

    ip_rule {
      ip_mask = "10.0.1.0/24"
      action  = "Allow"
    }

    ip_rule {
      ip_mask = "10.1.1.0/24"
    }
  }
  tags = {
    yor_trace = "bf5173b3-b350-4ac7-9133-b7e069758544"
  }
}