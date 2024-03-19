# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "azurerm_subnet" "gateway_snet_1" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name_1
  virtual_network_name = var.vnet_name_1
  address_prefixes     = [var.gateway_subnet_range_1]
}

resource "azurerm_public_ip" "pip_1" {
  name                = "${var.prefix}_pip_1"
  location            = var.location_1
  resource_group_name = var.resource_group_name_1
  allocation_method   = "Dynamic"
  tags = {
    yor_trace = "27cdcff7-2a22-4f47-8521-4a19962984c8"
  }
}

resource "azurerm_virtual_network_gateway" "vnet_gw_1" {
  name                = "${var.prefix}_vnet_gw_1"
  location            = var.location_1
  resource_group_name = var.resource_group_name_1

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_snet_1.id
  }
  tags = {
    yor_trace = "3d9a72bd-49bb-4893-8682-20a7a8a9d6ff"
  }
}

resource "azurerm_virtual_network_gateway_connection" "gw_connection_1" {
  name                = "${var.prefix}_gw_connection_1"
  location            = var.location_1
  resource_group_name = var.resource_group_name_1

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vnet_gw_1.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vnet_gw_2.id

  shared_key = var.shared_key
  tags = {
    yor_trace = "abcb855b-9667-4ec2-abe1-a2d428449432"
  }
}

resource "azurerm_subnet" "gateway_snet_2" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name_2
  virtual_network_name = var.vnet_name_2
  address_prefixes     = [var.gateway_subnet_range_2]
}

resource "azurerm_public_ip" "pip_2" {
  name                = "${var.prefix}_pip_2"
  location            = var.location_2
  resource_group_name = var.resource_group_name_2
  allocation_method   = "Dynamic"
  tags = {
    yor_trace = "a34d0e4c-802c-4c43-a0b1-4e0a99c4f0af"
  }
}

resource "azurerm_virtual_network_gateway" "vnet_gw_2" {
  name                = "${var.prefix}_vnet_gw_2"
  location            = var.location_2
  resource_group_name = var.resource_group_name_2

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip_2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_snet_2.id
  }
  tags = {
    yor_trace = "f47516c3-63bc-4a9c-bf04-619fc68e5597"
  }
}

resource "azurerm_virtual_network_gateway_connection" "gw_connection_2" {
  name                = "${var.prefix}_gw_connection_2"
  location            = var.location_2
  resource_group_name = var.resource_group_name_2

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vnet_gw_2.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vnet_gw_1.id

  shared_key = var.shared_key
  tags = {
    yor_trace = "bd0d9832-51e3-4001-8d55-e7d3fb046104"
  }
}
