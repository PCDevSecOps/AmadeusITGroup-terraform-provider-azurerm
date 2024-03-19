# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

provider "random" {}

resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "West Europe"
  tags = {
    yor_trace = "141d96b8-23a3-4a86-beed-f08a33c44174"
  }
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-workspace"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  tags = {
    yor_trace = "b32aa86e-52f9-49a7-bbf0-55479a619837"
  }
}

resource "azurerm_log_analytics_solution" "example" {
  solution_name         = "SecurityInsights"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  workspace_resource_id = azurerm_log_analytics_workspace.example.id
  workspace_name        = azurerm_log_analytics_workspace.example.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
  tags = {
    yor_trace = "9fac8568-ba86-4b90-a183-d17999f714da"
  }
}

resource "azurerm_sentinel_watchlist" "example" {
  name                       = "example-watchlist"
  log_analytics_workspace_id = azurerm_log_analytics_solution.example.workspace_resource_id
  display_name               = "example-wl"
  item_search_key            = "Key"
}

locals {
  csv_data = csvdecode(file("./data.csv"))
}

resource "random_uuid" "item" {
  count = length(local.csv_data)
}

resource "azurerm_sentinel_watchlist_item" "example" {
  count = length(local.csv_data)

  name         = random_uuid.item[count.index].id
  watchlist_id = azurerm_sentinel_watchlist.example.id
  properties   = local.csv_data[count.index]
}
