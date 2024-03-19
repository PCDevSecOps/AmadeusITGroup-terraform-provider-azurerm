# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "32450b0a-1e3c-40ca-a4ef-aa8549f27f5a"
  }
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.prefix}-laworkspace"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  tags = {
    yor_trace = "29b98057-a8dd-49cf-8ee3-eb2c4ec1b964"
  }
}

resource "azurerm_log_analytics_solution" "test" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  workspace_resource_id = azurerm_log_analytics_workspace.example.id
  workspace_name        = azurerm_log_analytics_workspace.example.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
  tags = {
    yor_trace = "81c3ed00-0060-4486-af72-35a666dc891e"
  }
}

resource "azurerm_log_analytics_solution" "test2" {
  solution_name         = "Security"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  workspace_resource_id = azurerm_log_analytics_workspace.example.id
  workspace_name        = azurerm_log_analytics_workspace.example.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }
  tags = {
    yor_trace = "ed602298-f0db-4ea3-8fd0-a1e7a3040bb3"
  }
}
