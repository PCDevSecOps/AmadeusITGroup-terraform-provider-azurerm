# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "04082c12-e006-4fd2-b722-efb42f0d83bf"
  }
}

resource "azurerm_virtual_desktop_workspace" "example" {
  name                = "${var.prefix}workspace"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tags = {
    yor_trace = "3ac0ad6d-acde-46c9-8f39-3b648b49e885"
  }
}

resource "azurerm_virtual_desktop_host_pool" "example" {
  resource_group_name = azurerm_resource_group.example.name
  name                = "${var.prefix}hostpool"
  location            = azurerm_resource_group.example.location

  validate_environment     = false
  type                     = "Pooled"
  maximum_sessions_allowed = 16
  load_balancer_type       = "BreadthFirst"
  tags = {
    yor_trace = "f53fd163-50c0-43cd-93f5-4a1dabb09351"
  }
}

resource "azurerm_virtual_desktop_application_group" "example" {
  resource_group_name = azurerm_resource_group.example.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.example.id
  location            = azurerm_resource_group.example.location
  type                = "Desktop"
  name                = "${var.prefix}dag"
  depends_on          = [azurerm_virtual_desktop_host_pool.example]
  tags = {
    yor_trace = "985fa7f6-df6d-4637-a73a-92a4947ca096"
  }
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "example" {
  application_group_id = azurerm_virtual_desktop_application_group.example.id
  workspace_id         = azurerm_virtual_desktop_workspace.example.id
}
