# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-aks-resources"
  location = var.location
  tags = {
    yor_trace = "e91f0e97-31e6-477e-94d5-98f8a2c96d67"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["192.168.0.0/16"]
  tags = {
    yor_trace = "749a1230-a192-4dfa-88be-d4b5b0778dbd"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["192.168.1.0/24"]
  virtual_network_name = azurerm_virtual_network.example.name
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "example-dns-prefix"

  default_node_pool {
    name           = "examplepool"
    node_count     = 2
    vm_size        = "Standard_B2s"
    vnet_subnet_id = azurerm_subnet.example.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
  tags = {
    yor_trace = "ac876feb-9dbd-419e-8d58-2e0cd0c9b1c0"
  }
}

data "azurerm_public_ip" "example" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.example.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.example.node_resource_group
}
