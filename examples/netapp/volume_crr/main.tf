# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "69e03a10-705d-4e1a-8d7f-259df9724b64"
  }
}

resource "azurerm_virtual_network" "example_primary" {
  name                = "${var.prefix}-virtualnetwork-primary"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    yor_trace = "d2718581-d411-40b6-96de-2d8256dfd633"
  }
}

resource "azurerm_subnet" "example_primary" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example_primary.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "testdelegation"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_virtual_network" "example_secondary" {
  name                = "${var.prefix}-virtualnetwork-secondary"
  location            = var.alt_location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.1.0.0/16"]
  tags = {
    yor_trace = "68c56480-9c5a-4799-9ea3-eb16091c45e8"
  }
}

resource "azurerm_subnet" "example_secondary" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example_secondary.name
  address_prefixes     = ["10.1.2.0/24"]

  delegation {
    name = "testdelegation"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_netapp_account" "example_primary" {
  name                = "${var.prefix}-netappaccount-primary"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "73978236-398a-49e9-9a3a-ee4b6f843553"
  }
}

resource "azurerm_netapp_account" "example_secondary" {
  name                = "${var.prefix}-netappaccount-secondary"
  location            = var.alt_location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "3d799a76-76a3-40ee-a8ef-1a67310617c3"
  }
}

resource "azurerm_netapp_pool" "example_primary" {
  name                = "${var.prefix}-netapppool-primary"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example_primary.name
  service_level       = "Premium"
  size_in_tb          = 4
  tags = {
    yor_trace = "8c4b7ff0-a5ad-488d-b101-508b83379425"
  }
}

resource "azurerm_netapp_pool" "example_secondary" {
  name                = "${var.prefix}-netapppool-secondary"
  location            = var.alt_location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example_secondary.name
  service_level       = "Standard"
  size_in_tb          = 4
  tags = {
    yor_trace = "52745e4a-436f-4ca9-a780-0aa3558ed937"
  }
}

resource "azurerm_netapp_volume" "example_primary" {
  lifecycle {
    prevent_destroy = true
  }

  name                = "${var.prefix}-netappvolume-primary"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example_primary.name
  pool_name           = azurerm_netapp_pool.example_primary.name
  volume_path         = "${var.prefix}-netappvolume"
  service_level       = "Standard"
  protocols           = ["NFSv3"]
  subnet_id           = azurerm_subnet.example_primary.id
  storage_quota_in_gb = 100

  export_policy_rule {
    rule_index        = 1
    allowed_clients   = ["0.0.0.0/0"]
    protocols_enabled = ["NFSv3"]
    unix_read_only    = false
    unix_read_write   = true
  }
  tags = {
    yor_trace = "929414c0-5b07-463a-8188-1bb5abf55a38"
  }
}

resource "azurerm_netapp_volume" "example_secondary" {
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [azurerm_netapp_volume.example_primary]

  name                = "${var.prefix}-netappvolume-secondary"
  location            = var.alt_location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example_secondary.name
  pool_name           = azurerm_netapp_pool.example_secondary.name
  volume_path         = "${var.prefix}-netappvolume-secondary"
  service_level       = "Standard"
  protocols           = ["NFSv3"]
  subnet_id           = azurerm_subnet.example_secondary.id
  storage_quota_in_gb = 100

  export_policy_rule {
    rule_index        = 1
    allowed_clients   = ["0.0.0.0/0"]
    protocols_enabled = ["NFSv3"]
    unix_read_only    = false
    unix_read_write   = true
  }

  data_protection_replication {
    endpoint_type             = "dst"
    remote_volume_location    = azurerm_resource_group.example.location
    remote_volume_resource_id = azurerm_netapp_volume.example_primary.id
    replication_frequency     = "10minutes"
  }
  tags = {
    yor_trace = "d2b71f7e-4313-497c-8129-1a62724410b8"
  }
}
