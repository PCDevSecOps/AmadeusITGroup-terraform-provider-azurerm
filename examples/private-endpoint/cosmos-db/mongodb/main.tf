# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "311541ce-8db4-41b1-a99e-2ad45448cb40"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "4ec4985b-0a46-4c03-9a01-bca6e161d484"
  }
}

resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  private_endpoint_network_policies_enabled = false
}

resource "azurerm_cosmosdb_account" "example" {
  name                = "${var.prefix}-cosmosdb-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover         = false
  is_virtual_network_filter_enabled = true

  // set ip_range_filter to allow azure services (0.0.0.0) and azure portal.
  // https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-the-azure-portal
  // https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-global-azure-datacenters-or-other-sources-within-azure
  ip_range_filter = "0.0.0.0,104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26"

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 310
    max_staleness_prefix    = 101000
  }

  geo_location {
    location          = azurerm_resource_group.example.location
    failover_priority = 0
  }
  tags = {
    yor_trace = "90631adf-849c-42cb-9308-2da7be1fbc44"
  }
}

resource "azurerm_private_endpoint" "example" {
  name                = "${var.prefix}-pe"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "tfex-cosmosdb-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cosmosdb_account.example.id
    subresource_names              = ["MongoDB"]
  }
  tags = {
    yor_trace = "51628e2b-f457-45f3-bb9e-6289c62a8e19"
  }
}
