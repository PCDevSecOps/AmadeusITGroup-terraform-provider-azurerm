# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "8ce4e0c4-3c45-4ed3-8334-694864443049"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.1.0.0/16"]
  tags = {
    yor_trace = "62cecede-6f54-4164-b689-d8c07306eef9"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.1.0.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_container_group" "example" {
  name                = "${var.prefix}continst"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "hello-world"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  container {
    name   = "sidecar"
    image  = "mcr.microsoft.com/azuredocs/aci-tutorial-sidecar"
    cpu    = "0.5"
    memory = "1.5"
  }

  subnet_ids = [azurerm_subnet.example.id]

  tags = {
    environment = "testing"
    yor_trace   = "94b527f1-edc2-4e43-b5c8-382682da61d0"
  }
}
