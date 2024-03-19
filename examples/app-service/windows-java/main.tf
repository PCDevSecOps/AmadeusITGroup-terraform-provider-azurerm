# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "ab592859-cc40-4d28-857a-7af7cef333b1"
  }
}

resource "azurerm_service_plan" "example" {
  name                = "${var.prefix}-sp"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  os_type             = "Windows"
  sku_name            = "B1"
}

resource "azurerm_windows_web_app" "example" {
  name                = "${var.prefix}-basic-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  service_plan_id     = azurerm_service_plan.example.id

  site_config {
    application_stack {
      current_stack          = "java"
      java_version           = "11"
      java_container         = "JAVA"
      java_container_version = "SE"
    }
  }
}