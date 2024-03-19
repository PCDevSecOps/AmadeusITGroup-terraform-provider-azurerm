# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "f2f56643-7e4e-42f5-9c1c-dc59e7b9e093"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-virtualnetwork"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    yor_trace = "fa3425f7-c06d-4d38-8115-cd3bbfaba68e"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "testdelegation"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_netapp_account" "example" {
  name                = "${var.prefix}-netappaccount"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "dbfd7cff-24b8-402f-99c7-9c87a77e8837"
  }
}

resource "azurerm_netapp_snapshot_policy" "example" {
  name                = "${var.prefix}-snapshotpolicy"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example.name
  enabled             = true

  hourly_schedule {
    snapshots_to_keep = 4
    minute            = 15
  }

  daily_schedule {
    snapshots_to_keep = 2
    hour              = 20
    minute            = 15
  }

  weekly_schedule {
    snapshots_to_keep = 1
    days_of_week      = ["Monday", "Friday"]
    hour              = 23
    minute            = 0
  }

  monthly_schedule {
    snapshots_to_keep = 1
    days_of_month     = [1, 15, 20, 30]
    hour              = 5
    minute            = 45
  }
}

resource "azurerm_netapp_pool" "example" {
  name                = "${var.prefix}-netapppool"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example.name
  service_level       = "Standard"
  size_in_tb          = 4
  tags = {
    yor_trace = "b76bc5c4-3427-43e9-b3cf-1c8f435e38a7"
  }
}

resource "azurerm_netapp_volume" "example" {
  lifecycle {
    prevent_destroy = true
  }

  name                = "${var.prefix}-netappvolume"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example.name
  pool_name           = azurerm_netapp_pool.example.name
  volume_path         = "${var.prefix}-netappvolume"
  service_level       = "Standard"
  protocols           = ["NFSv3"]
  subnet_id           = azurerm_subnet.example.id
  storage_quota_in_gb = 100
  security_style      = "unix"

  data_protection_snapshot_policy {
    snapshot_policy_id = azurerm_netapp_snapshot_policy.example.id
  }
  tags = {
    yor_trace = "37479190-81cd-474d-afaf-89f950121c10"
  }
}
