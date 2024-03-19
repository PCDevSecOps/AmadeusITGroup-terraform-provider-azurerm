# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "cc405597-0e30-4aa6-9b5c-02162c224b6c"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-virtualnetwork"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    yor_trace = "0ab37a6c-e090-4ac7-90e0-e86d42992d21"
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
    yor_trace = "0fc96515-d9f1-41d8-a53d-05dc3f056262"
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
    yor_trace = "e64fc990-6cc4-4f15-8fd2-be765c2e03de"
  }
}

resource "azurerm_netapp_volume" "example" {
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

  export_policy_rule {
    rule_index        = 1
    allowed_clients   = ["0.0.0.0/0"]
    protocols_enabled = ["NFSv3"]
    unix_read_write   = true
  }
  tags = {
    yor_trace = "3b5de97b-cb3f-44f1-a3f0-53cc4aefd3e5"
  }
}

resource "azurerm_netapp_snapshot" "example" {
  name                = "${var.prefix}-netappsnapshot"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example.name
  pool_name           = azurerm_netapp_pool.example.name
  volume_name         = azurerm_netapp_volume.example.name
  tags = {
    yor_trace = "b56d5dd0-5f7c-42df-836b-634deaca8fce"
  }
}

resource "azurerm_netapp_volume" "example-snapshot" {
  name                             = "${var.prefix}-netappvolume-snapshot"
  location                         = azurerm_resource_group.example.location
  resource_group_name              = azurerm_resource_group.example.name
  account_name                     = azurerm_netapp_account.example.name
  pool_name                        = azurerm_netapp_pool.example.name
  volume_path                      = "${var.prefix}-netappvolume-snapshot"
  service_level                    = "Standard"
  protocols                        = ["NFSv3"]
  subnet_id                        = azurerm_subnet.example.id
  storage_quota_in_gb              = 100
  create_from_snapshot_resource_id = azurerm_netapp_snapshot.example.id

  export_policy_rule {
    rule_index        = 1
    allowed_clients   = ["0.0.0.0/0"]
    protocols_enabled = ["NFSv3"]
    unix_read_write   = true
  }
  tags = {
    yor_trace = "83611d46-3b2c-4ab1-b99b-92d669f00af4"
  }
}
