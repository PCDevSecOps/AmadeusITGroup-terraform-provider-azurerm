# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "d0fbc594-ff7b-4097-9d9b-14931c471c75"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "e0787d38-377b-4969-9325-c1dbff052eab"
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "${var.prefix}-nsgrule"
  network_security_group_name = azurerm_network_security_group.example.name
  resource_group_name         = azurerm_resource_group.example.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Sql.WestEurope"
}
