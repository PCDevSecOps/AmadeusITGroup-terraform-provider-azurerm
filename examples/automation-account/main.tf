# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "b838b097-a030-4a9d-b7c7-f7993b50d5d2"
  }
}

resource "azurerm_automation_account" "example" {
  name                = "${var.prefix}-autoacc"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku {
    name = "Basic"
  }
  tags = {
    yor_trace = "dc78f73c-68dd-42b0-b866-09515671ca20"
  }
}

resource "azurerm_automation_runbook" "example" {
  name                = "Get-AzureVMTutorial"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_automation_account.example.name
  log_verbose         = "true"
  log_progress        = "true"
  description         = "This is an example runbook"
  runbook_type        = "PowerShellWorkflow"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  }
  tags = {
    yor_trace = "ddf90515-02b9-404b-8840-596e963bc0b7"
  }
}

resource "azurerm_automation_schedule" "one-time" {
  name                    = "${var.prefix}-one-time"
  resource_group_name     = azurerm_resource_group.example.name
  automation_account_name = azurerm_automation_account.example.name
  frequency               = "OneTime"

  // The start_time defaults to now + 7 min
}

resource "azurerm_automation_schedule" "hour" {
  name                    = "${var.prefix}-hour"
  resource_group_name     = azurerm_resource_group.example.name
  automation_account_name = azurerm_automation_account.example.name
  frequency               = "Hour"
  interval                = 2

  // Timezone defaults to UTC
}

// Schedules the example runbook to run on the hour schedule
resource "azurerm_automation_job_schedule" "example" {
  resource_group_name     = azurerm_resource_group.example.name
  automation_account_name = azurerm_automation_account.example.name
  runbook_name            = azurerm_automation_runbook.example.name
  schedule_name           = azurerm_automation_schedule.hour.name
}
