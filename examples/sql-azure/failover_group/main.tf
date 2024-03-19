# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "d96a60a6-3d0c-47d4-813b-5be3db41f9fe"
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
    yor_trace = "d33d7369-613c-45f0-9bd0-3b35d65a0726"
  }
}

resource "azurerm_mssql_server" "secondary" {
  name                         = "${var.prefix}-server-secondary"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = var.location_alt
  version                      = "12.0"
  administrator_login          = "mradministrator"
  administrator_login_password = "thisIsDog11"
  tags = {
    yor_trace = "5ed99173-885b-41a9-9dc4-f44cb767c1e6"
  }
}

resource "azurerm_mssql_database" "example" {
  name         = "${var.prefix}-db-primary"
  server_id    = azurerm_mssql_server.example.id
  collation    = "SQL_AltDiction_CP850_CI_AI"
  license_type = "BasePrice"
  sku_name     = "GP_Gen5_2"
  tags = {
    yor_trace = "e7ea5cef-832f-4ffc-b9a0-50425efe3d34"
  }
}

resource "azurerm_mssql_database" "secondary" {
  name                        = "${var.prefix}-db-secondary"
  server_id                   = azurerm_mssql_server.secondary.id
  create_mode                 = "Secondary"
  creation_source_database_id = azurerm_mssql_database.example.id
  tags = {
    yor_trace = "52fc49dc-3773-4e2c-a09c-236d75927a54"
  }
}

resource "azurerm_sql_failover_group" "example" {
  name                = "${var.prefix}-failover-group"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  databases           = [azurerm_mssql_database.example.id]

  partner_servers {
    id = azurerm_mssql_server.secondary.id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }

  depends_on = [azurerm_mssql_database.secondary]
  tags = {
    yor_trace = "cf887d65-0455-4e8d-a4b7-fb7627afa0f6"
  }
}