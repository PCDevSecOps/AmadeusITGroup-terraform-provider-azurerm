# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-functions-python-rg"
  location = var.location
  tags = {
    yor_trace = "85bfbf33-d5b2-4f80-b103-8ba3632e9109"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}storageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    yor_trace = "7de24098-0185-485f-a8de-8c936f74e00e"
  }
}

resource "azurerm_service_plan" "example" {
  name                = "${var.prefix}-sp"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "${var.prefix}-python-example-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  service_plan_id     = azurerm_service_plan.example.id

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

resource "azurerm_function_app_function" "example" {
  name            = "example-python-function"
  function_app_id = azurerm_linux_function_app.example.id
  language        = "Python"
  file {
    name    = "__init__.py"
    content = file("./SampleApp/PythonSampleApp/__init__.py")
  }
  test_data = file("./SampleApp/PythonSampleApp/sample.dat")
  #  test_data = jsonencode({
  #    "name" = "Azure"
  #  })
  config_json = file("./SampleApp/PythonSampleApp/function.json")
  #  config_json = jsonencode({
  #    "scriptFile" = "__init__.py"
  #    "bindings" = [
  #      {
  #        "authLevel" = "anonymous"
  #        "direction" = "in"
  #        "methods" = [
  #          "get",
  #          "post",
  #        ]
  #        "name" = "req"
  #        "type" = "httpTrigger"
  #      },
  #      {
  #        "direction" = "out"
  #        "name"      = "$return"
  #        "type"      = "http"
  #      },
  #    ]
  #  })
}