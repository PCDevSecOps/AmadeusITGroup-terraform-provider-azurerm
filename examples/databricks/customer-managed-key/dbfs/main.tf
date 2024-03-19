# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-databricks-cmk"
  location = "West Europe"
  tags = {
    yor_trace = "e8ec07ea-c16d-4e25-aab0-46db77d904e1"
  }
}

resource "azurerm_databricks_workspace" "example" {
  name                        = "${var.prefix}-DBW"
  resource_group_name         = azurerm_resource_group.example.name
  location                    = azurerm_resource_group.example.location
  sku                         = "premium"
  managed_resource_group_name = "${var.prefix}-DBW-managed-dbfs"

  customer_managed_key_enabled = true

  tags = {
    Environment = "Production"
    yor_trace   = "050f5ed2-f872-4c63-93c2-d7434375ccca"
  }
}

resource "azurerm_databricks_workspace_root_dbfs_customer_managed_key" "example" {
  depends_on = [azurerm_key_vault_access_policy.databricks]

  workspace_id     = azurerm_databricks_workspace.example.id
  key_vault_key_id = azurerm_key_vault_key.example.id
}

resource "azurerm_key_vault" "example" {
  name                = "${var.prefix}-keyvault"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  tags = {
    yor_trace = "699efc9d-3586-47ca-8000-ba5e328c90ae"
  }
}

resource "azurerm_key_vault_key" "example" {
  depends_on = [azurerm_key_vault_access_policy.terraform]

  name         = "${var.prefix}-certificate"
  key_vault_id = azurerm_key_vault.example.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "Decrypt",
    "Encrypt",
    "Sign",
    "UnwrapKey",
    "Verify",
    "WrapKey",
  ]
  tags = {
    yor_trace = "dd3fc657-4f71-4370-a4f7-f93a53f440bf"
  }
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = azurerm_key_vault.example.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Decrypt",
    "Encrypt",
    "Sign",
    "UnwrapKey",
    "Verify",
    "WrapKey",
    "Delete",
    "Restore",
    "Recover",
    "Update",
    "Purge",
  ]
}

resource "azurerm_key_vault_access_policy" "databricks" {
  depends_on = [azurerm_databricks_workspace.example]

  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = azurerm_databricks_workspace.example.storage_account_identity.0.tenant_id
  object_id    = azurerm_databricks_workspace.example.storage_account_identity.0.principal_id

  key_permissions = [
    "get",
    "unwrapKey",
    "wrapKey",
  ]
}
