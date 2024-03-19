# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy       = false
      purge_soft_deleted_keys_on_destroy = false
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "test" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "ede5a38b-ed33-46e3-898a-1ac884a737a3"
  }
}

resource "azurerm_key_vault" "test" {
  name                        = "${var.prefix}kv"
  location                    = azurerm_resource_group.test.location
  resource_group_name         = azurerm_resource_group.test.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  tags = {
    yor_trace = "1a0e0606-138b-4952-9cfc-9f8e425a5a91"
  }
}

resource "azurerm_key_vault_access_policy" "service-principal" {
  key_vault_id = azurerm_key_vault.test.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Update",
  ]

  secret_permissions = [
    "Get",
    "Delete",
    "Set",
  ]
}

resource "azurerm_key_vault_key" "test" {
  name         = "examplekey"
  key_vault_id = azurerm_key_vault.test.id
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

  depends_on = [
    azurerm_key_vault_access_policy.service-principal
  ]
  tags = {
    yor_trace = "f16596ff-63d3-4c85-8eb3-03a744cfade4"
  }
}

resource "azurerm_virtual_network" "test" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  tags = {
    yor_trace = "fe1f48fe-0a72-4223-a57c-8fc7b94ef636"
  }
}

resource "azurerm_subnet" "test" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "test" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    yor_trace = "4dd9a629-b6eb-4445-a619-65717a1bd6c2"
  }
}

resource "azurerm_linux_virtual_machine" "test" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.test.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  tags = {
    yor_trace = "fcfe266c-7f63-4d85-a0e0-acc7013f161d"
  }
}

resource "azurerm_virtual_machine_extension" "test" {
  name                       = "AzureDiskEncryptionForLinux"
  publisher                  = "Microsoft.Azure.Security"
  type                       = "AzureDiskEncryptionForLinux"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = false
  virtual_machine_id         = azurerm_linux_virtual_machine.test.id

  settings = <<SETTINGS
{
  "EncryptionOperation": "EnableEncryption",
  "KeyEncryptionAlgorithm": "RSA-OAEP",
  "KeyVaultURL": "${azurerm_key_vault.test.vault_uri}",
  "KeyVaultResourceId": "${azurerm_key_vault.test.id}",
  "KeyEncryptionKeyURL": "${azurerm_key_vault_key.test.id}",
  "KekVaultResourceId": "${azurerm_key_vault.test.id}",
  "VolumeType": "All"
}
SETTINGS
  tags = {
    yor_trace = "f72c64ca-4f6d-48c0-8422-25b7d1c0155a"
  }
}
