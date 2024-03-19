# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "fe9584d2-42d4-46e7-897b-eb2ea381f275"
  }
}

resource "azurerm_data_lake_store" "example" {
  name                = "${var.prefix}-dls"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tier                = "Consumption"
  tags = {
    yor_trace = "0b400af6-3f7e-458e-b48d-879d76d94527"
  }
}

resource "azurerm_data_lake_store_firewall_rule" "test" {
  name                = "${var.prefix}-dls-fwrule"
  account_name        = azurerm_data_lake_store.example.name
  resource_group_name = azurerm_resource_group.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_data_lake_analytics_account" "example" {
  name                       = "${var.prefix}-dla"
  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  tier                       = "Consumption"
  default_store_account_name = azurerm_data_lake_store.example.name
  tags = {
    yor_trace = "e8e84dd5-7fca-410a-b838-73f832d084ac"
  }
}

resource "azurerm_data_lake_analytics_firewall_rule" "test" {
  name                = "${var.prefix}-dlafwrule"
  account_name        = azurerm_data_lake_analytics_account.example.name
  resource_group_name = azurerm_resource_group.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
