# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "ad0c022a-5e9b-44c8-a4e3-e09c5f738123"
  }
}

resource "azurerm_netapp_account" "example" {
  name                = "${var.prefix}-netappaccount"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "288048cd-3a91-49be-82d7-5206bbf3929d"
  }
}

resource "azurerm_netapp_pool" "example" {
  name                = "${var.prefix}-netapppool"
  account_name        = azurerm_netapp_account.example.name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  service_level       = "Premium"
  size_in_tb          = 4
  tags = {
    yor_trace = "d3daf245-f921-4e4f-af82-5a786385a670"
  }
}
