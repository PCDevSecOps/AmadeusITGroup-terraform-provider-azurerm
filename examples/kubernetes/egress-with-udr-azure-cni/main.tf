# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-k8s-resources"
  location = var.location
  tags = {
    yor_trace = "5d81ca20-a272-4477-9dd2-92b9e49ef6e1"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.1.0.0/16"]
  tags = {
    yor_trace = "29b88059-c3c3-4cd1-a606-d0bb11895766"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["10.1.0.0/22"]
}

resource "azurerm_route_table" "example" {
  name                          = "${var.prefix}fwrt"
  location                      = azurerm_resource_group.example.location
  resource_group_name           = azurerm_resource_group.example.name
  disable_bgp_route_propagation = false

  route {
    name                   = "${var.prefix}fwrn"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fwprivate_ip
  }
  tags = {
    yor_trace = "f51a49b7-5500-4f90-baa5-567adf1f8a86"
  }
}

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.internal.id
  route_table_id = azurerm_route_table.example.id
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "${var.prefix}-k8s"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "${var.prefix}-k8s"

  default_node_pool {
    name           = "system"
    node_count     = 1
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.internal.id
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "userDefinedRouting"
  }

  identity {
    type = "SystemAssigned"
  }
  tags = {
    yor_trace = "c2ebf475-cd9a-481a-ac66-41d5e032ce50"
  }
}
