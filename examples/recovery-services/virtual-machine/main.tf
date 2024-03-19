# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "c96ba66c-a592-400f-afe2-d2fd8c28b7db"
  }
}

module "virtual-network" {
  source              = "./modules/virtual-network"
  resource_group_name = azurerm_resource_group.example.name
  prefix              = var.prefix
}

module "virtual-machine" {
  source              = "./modules/virtual-machine"
  resource_group_name = azurerm_resource_group.example.name
  prefix              = var.prefix
  subnet_id           = module.virtual-network.subnet_id
}

resource "azurerm_recovery_services_vault" "example" {
  name                = "${var.prefix}-vault"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags = {
    yor_trace = "7e7d14c5-3ba1-4c85-a1cb-606fd38e7d79"
  }
}

resource "azurerm_backup_policy_vm" "example" {
  name                = "tfex-policy-simple"
  resource_group_name = azurerm_resource_group.example.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }
  tags = {
    yor_trace = "2316d217-7177-49cb-aef9-85ca210775ac"
  }
}

resource "azurerm_backup_protected_vm" "example" {
  resource_group_name = azurerm_resource_group.example.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name
  source_vm_id        = module.virtual-machine.id
  backup_policy_id    = azurerm_backup_policy_vm.example.id
  tags = {
    yor_trace = "81b47ce8-719e-4b2d-ba0f-022dbf8a694b"
  }
}
