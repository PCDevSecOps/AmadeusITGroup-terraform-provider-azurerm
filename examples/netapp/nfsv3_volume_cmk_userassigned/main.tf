# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "a01d9b87-03d5-43fd-a521-81e0ea6a5f88"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.6.0.0/16"]
  tags = {
    yor_trace = "4a7a6204-2e0d-4780-849e-7d11b2c875ad"
  }
}

resource "azurerm_subnet" "example-delegated" {
  name                 = "${var.prefix}-delegated-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.6.1.0/24"]

  delegation {
    name = "exampledelegation"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "example-non-delegated" {
  name                 = "${var.prefix}-non-delegated-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.6.0.0/24"]
}

resource "azurerm_key_vault" "example" {
  name                            = "${var.prefix}anfakv"
  location                        = azurerm_resource_group.example.location
  resource_group_name             = azurerm_resource_group.example.name
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true
  tenant_id                       = var.tenant_id

  sku_name = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "Create",
      "Delete",
      "WrapKey",
      "UnwrapKey",
      "GetRotationPolicy",
      "SetRotationPolicy",
    ]
  }

  access_policy {
    tenant_id = var.tenant_id
    object_id = azurerm_user_assigned_identity.example.principal_id

    key_permissions = [
      "Get",
      "Encrypt",
      "Decrypt"
    ]
  }
  tags = {
    yor_trace = "54d4c77d-d254-4a68-92fc-ebc7143a063d"
  }
}

resource "azurerm_key_vault_key" "example" {
  name         = "${var.prefix}anfenckey"
  key_vault_id = azurerm_key_vault.example.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  tags = {
    yor_trace = "7d034036-e06e-4bd9-aeca-618571224ece"
  }
}

resource "azurerm_private_endpoint" "example" {
  name                = "${var.prefix}-pe-akv"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example-non-delegated.id

  private_service_connection {
    name                           = "${var.prefix}-pe-sc-akv"
    private_connection_resource_id = azurerm_key_vault.example.id
    is_manual_connection           = false
    subresource_names              = ["Vault"]
  }
  tags = {
    yor_trace = "e076b83f-fa58-4b6c-8f65-fff9e1decc8c"
  }
}

resource "azurerm_user_assigned_identity" "example" {
  name                = "${var.prefix}-user-assigned-identity"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "d0a62e68-6e1b-4d40-b8ff-d19cc33beb8c"
  }
}

resource "azurerm_netapp_account" "example" {
  name                = "${var.prefix}-netappaccount"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.example.id
    ]
  }
  tags = {
    yor_trace = "a854d398-d7b5-46d0-87ff-16765b299ddc"
  }
}

resource "azurerm_netapp_account_encryption" "example" {
  netapp_account_id = azurerm_netapp_account.example.id

  user_assigned_identity_id = azurerm_user_assigned_identity.example.id

  encryption_key = azurerm_key_vault_key.example.versionless_id
}

resource "azurerm_netapp_pool" "example" {
  name                = "${var.prefix}-pool"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example.name
  service_level       = "Standard"
  size_in_tb          = 4

  depends_on = [
    azurerm_netapp_account_encryption.example
  ]
  tags = {
    yor_trace = "faf46c6a-8f2a-4bcb-aa3f-7f42d6cb2816"
  }
}

resource "azurerm_netapp_volume" "example" {
  name                          = "${var.prefix}-vol"
  location                      = azurerm_resource_group.example.location
  resource_group_name           = azurerm_resource_group.example.name
  account_name                  = azurerm_netapp_account.example.name
  pool_name                     = azurerm_netapp_pool.example.name
  volume_path                   = "${var.prefix}-my-unique-file-path-vol"
  service_level                 = "Standard"
  subnet_id                     = azurerm_subnet.example-delegated.id
  storage_quota_in_gb           = 100
  network_features              = "Standard"
  encryption_key_source         = "Microsoft.KeyVault"
  key_vault_private_endpoint_id = azurerm_private_endpoint.example.id

  export_policy_rule {
    rule_index          = 1
    allowed_clients     = ["0.0.0.0/0"]
    protocols_enabled   = ["NFSv3"]
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }

  depends_on = [
    azurerm_netapp_account_encryption.example,
    azurerm_private_endpoint.example
  ]
  tags = {
    yor_trace = "ea10e6ab-72d6-4c56-b37a-df457eafaaf9"
  }
}
