# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "0387fe67-7e80-4637-af27-56f7f565dab2"
  }
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.prefix}-laworkspace"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  tags = {
    yor_trace = "c329ba87-c9a2-4410-801b-87c6187b0174"
  }
}
