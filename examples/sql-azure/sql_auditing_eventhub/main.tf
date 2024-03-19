# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "c05973c5-4197-455b-a6e0-a377bb3cc14e"
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
    yor_trace = "4fee5496-949f-4f22-a41d-56e0e68e3c39"
  }
}

resource "azurerm_mssql_database" "example" {
  name      = "${var.prefix}-db-primary"
  server_id = azurerm_mssql_server.example.id
  tags = {
    yor_trace = "a2178141-0b00-471a-9f05-63875f2f111f"
  }
}

resource "azurerm_eventhub_namespace" "example" {
  name                = "${var.prefix}-EHN"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags = {
    yor_trace = "4489c811-92ff-4f57-8f7a-bad74c809a2e"
  }
}

resource "azurerm_eventhub" "example" {
  name                = "${var.prefix}-EH"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "example" {
  name                = "${var.prefix}EHRule"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  listen              = true
  send                = true
  manage              = true
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                           = "${var.prefix}-DS"
  target_resource_id             = azurerm_mssql_database.example.id
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.example.id
  eventhub_name                  = azurerm_eventhub.example.name

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
  database_id            = azurerm_mssql_database.example.id
  log_monitoring_enabled = true
}

resource "azurerm_mssql_server_extended_auditing_policy" "example" {
  server_id              = azurerm_mssql_server.example.id
  log_monitoring_enabled = true
}