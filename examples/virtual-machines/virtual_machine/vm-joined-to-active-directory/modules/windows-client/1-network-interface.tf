# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "azurerm_public_ip" "static" {
  name                = "${var.prefix}-client-ppip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  tags = {
    yor_trace = "0126798a-c6d4-40b1-8bf4-b73a8fa59196"
  }
}

resource "azurerm_network_interface" "primary" {
  name                    = "${var.prefix}-client-nic"
  location                = var.location
  resource_group_name     = var.resource_group_name
  internal_dns_name_label = local.virtual_machine_name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.static.id
  }
  tags = {
    yor_trace = "92195075-6f3b-416e-829a-b145634bcd0f"
  }
}
