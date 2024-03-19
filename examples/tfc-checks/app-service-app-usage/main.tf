# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "d6c99cf8-9518-4be0-8a29-2269b5fc99c3"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}storageaccount"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    yor_trace = "71a3414f-4b5e-444d-af12-7fc2a6f2db25"
  }
}

resource "azurerm_application_insights" "example" {
  name                = "${var.prefix}-appinsights"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  application_type    = "web"
  tags = {
    yor_trace = "9121b9a6-478c-4615-99b4-34d2f0e59876"
  }
}

resource "azurerm_service_plan" "example" {
  name                = "${var.prefix}-sp"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "${var.prefix}-LFA"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  service_plan_id     = azurerm_service_plan.example.id

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  site_config {
    application_insights_connection_string = azurerm_application_insights.example.connection_string
  }
}

data "azurerm_linux_function_app" "example" {
  name                = azurerm_linux_function_app.example.name
  resource_group_name = azurerm_linux_function_app.example.resource_group_name
}

check "check_vm_state" {
  assert {
    condition = data.azurerm_linux_function_app.example.usage == "Exceeded"
    error_message = format("Function App (%s) usage has been exceeded!",
      data.azurerm_linux_function_app.example.id,
    )
  }
}