# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "810211e8-d7ab-4e67-81fc-7fd93d6e0816"
  }
}

resource "azurerm_service_plan" "example" {
  name                = "${var.prefix}-sp"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}storageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    yor_trace = "60c6f7de-8084-403e-8270-605d9afa9577"
  }
}

resource "azurerm_linux_function_app" "example" {
  name                = "${var.prefix}-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  service_plan_id     = azurerm_service_plan.example.id

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  site_config {
    always_on = true

    application_stack {
      python_version = "3.11"
    }
  }
}

resource "azurerm_app_service_source_control" "example" {
  app_id                 = azurerm_linux_function_app.example.id
  repo_url               = "https://github.com/Azure-Samples/flask-app-on-azure-functions.git"
  branch                 = "main"
  use_manual_integration = true
}
