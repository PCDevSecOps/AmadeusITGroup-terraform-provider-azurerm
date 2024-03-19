# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "e0e7d765-39e9-47be-92b3-d8038fd80af2"
  }
}

resource "azurerm_logic_app_workflow" "example" {
  name                = "${var.prefix}-logicapp"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "e0a6dac0-d7df-43ad-ac44-ee31e7d18f19"
  }
}

resource "azurerm_logic_app_trigger_recurrence" "hourly" {
  name         = "run-every-hour"
  logic_app_id = azurerm_logic_app_workflow.example.id
  frequency    = "Hour"
  interval     = 1
}

resource "azurerm_logic_app_action_http" "main" {
  name         = "clear-stable-objects"
  logic_app_id = azurerm_logic_app_workflow.example.id
  method       = "DELETE"
  uri          = "http://example.com/clear-stable-objects"
}
