# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "9e1d841c-018c-419c-959e-7fd94c514270"
  }
}

resource "azurerm_netapp_account" "example" {
  name                = "${var.prefix}-netappaccount"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  active_directory {
    username            = "aduser"
    password            = "aduserpwd"
    smb_server_name     = "SMBSERVER"
    dns_servers         = ["1.2.3.4"]
    domain              = "westcentralus.com"
    organizational_unit = "OU=FirstLevel"
  }
  tags = {
    yor_trace = "761b3712-885c-4239-bbe2-a0affc258490"
  }
}
