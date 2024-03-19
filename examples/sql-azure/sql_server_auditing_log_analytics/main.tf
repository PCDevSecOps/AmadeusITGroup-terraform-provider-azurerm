# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "e0e9ec73-8c22-4e5c-bff5-b69a77937cdb"
  }
}

resource "azurerm_mssql_server" "example" {
  name                         = "${var.prefix}-server-primary"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "mradministrator"
  administrator_login_password = "thisIsDog11"
  tags = {
    yor_trace = "576c6da5-69d7-4c7e-a7c8-6eb199d31194"
  }
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.prefix}-LAW"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    yor_trace = "f70d9929-7aef-46fe-a076-714747ae5bbd"
  }
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "${var.prefix}-DS"
  target_resource_id         = "${azurerm_mssql_server.example.id}/databases/master"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  log {
    category = "SQLSecurityAuditEvents"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  lifecycle {
    ignore_changes = [log, metric]
  }
}

resource "azurerm_mssql_database_extended_auditing_policy" "example" {
  database_id            = "${azurerm_mssql_server.example.id}/databases/master"
  log_monitoring_enabled = true
}

resource "azurerm_mssql_server_extended_auditing_policy" "example" {
  server_id              = azurerm_mssql_server.example.id
  log_monitoring_enabled = true
}
