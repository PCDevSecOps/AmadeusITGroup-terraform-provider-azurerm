# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "0452a4ba-d8b6-4c97-86fb-562a73648b3e"
  }
}

resource "azurerm_recovery_services_vault" "example" {
  name                = "${var.prefix}-vault"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags = {
    yor_trace = "c3158ee0-754c-4c89-a4d0-b100b92ecffb"
  }
}

resource "azurerm_backup_policy_vm" "example" {
  name                = "${var.prefix}-policy"
  resource_group_name = azurerm_resource_group.example.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name
  timezone            = "UTC"

  backup {
    frequency = "Weekly"
    time      = "23:00"
    weekdays  = ["Monday", "Wednesday"]
  }

  retention_weekly {
    weekdays = ["Monday", "Wednesday"]
    count    = 52
  }

  retention_monthly {
    weeks    = ["First", "Second"]
    weekdays = ["Monday", "Wednesday"]
    count    = 100
  }

  retention_yearly {
    months   = ["July"]
    weeks    = ["First", "Second"]
    weekdays = ["Monday", "Wednesday"]
    count    = 100
  }
  tags = {
    yor_trace = "1faa8435-e34b-4b08-92a4-4fd058456454"
  }
}
