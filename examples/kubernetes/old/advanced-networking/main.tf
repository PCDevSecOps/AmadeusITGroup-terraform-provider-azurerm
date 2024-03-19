# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-anw-resources"
  location = var.location
  tags = {
    yor_trace = "5f712d4a-09f0-4318-911e-265ebac9614c"
  }
}

resource "azurerm_route_table" "example" {
  name                = "${var.prefix}-routetable"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  route {
    name                   = "default"
    address_prefix         = "10.100.0.0/14"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.1.1"
  }
  tags = {
    yor_trace = "6b5a24ca-2cc7-41c8-9427-279a81f2a8ed"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.1.0.0/16"]
  tags = {
    yor_trace = "2506726a-41c9-4caf-96ef-b9e130d93b78"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefix       = "10.1.0.0/22"
}

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.example.id
  route_table_id = azurerm_route_table.example.id
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "${var.prefix}-anw"
  location            = azurerm_resource_group.example.location
  dns_prefix          = "${var.prefix}-anw"
  resource_group_name = azurerm_resource_group.example.name

  linux_profile {
    admin_username = "acctestuser1"

    ssh_key {
      key_data = file(var.public_ssh_key_path)
    }
  }

  agent_pool_profile {
    name            = "agentpool"
    count           = "2"
    vm_size         = "Standard_DS2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30

    # Required for advanced networking
    vnet_subnet_id = azurerm_subnet.example.id
  }

  service_principal {
    client_id     = var.kubernetes_client_id
    client_secret = var.kubernetes_client_secret
  }

  network_profile {
    network_plugin = "azure"
  }

  depends_on = [azurerm_subnet_route_table_association.example]
  tags = {
    yor_trace = "8e8dd777-58e8-4cef-bf67-f8572618a389"
  }
}
