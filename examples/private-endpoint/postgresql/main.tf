# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "bd5d3f49-8073-4fd2-af78-0a36e1ec241c"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "71d841f2-feee-4e8e-a2a1-5cbfb4c8dec0"
  }
}

resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  private_endpoint_network_policies_enabled = false
}

resource "azurerm_postgresql_server" "example" {
  name                = "${var.prefix}-postgresql"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  auto_grow_enabled            = true
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  sku_name                     = "GP_Gen5_2"
  ssl_enforcement_enabled      = true
  storage_mb                   = 51200
  version                      = "11"
  tags = {
    yor_trace = "d1dd924f-37fc-40e2-a6fa-38ec35e44980"
  }
}

resource "azurerm_private_endpoint" "example" {
  name                = "${var.prefix}-pe"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "tfex-postgresql-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_postgresql_server.example.id
    subresource_names              = ["postgresqlServer"]
  }
  tags = {
    yor_trace = "94581723-e331-47af-a61e-3b6dcf8ca520"
  }
}
