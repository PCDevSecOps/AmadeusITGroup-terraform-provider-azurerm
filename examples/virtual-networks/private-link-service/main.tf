# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    yor_trace = "62f2e91e-a199-4547-998b-045b21b80254"
  }
}

resource "azurerm_virtual_network" "test" {
  name                = "acctestvnet"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  address_space       = ["10.5.0.0/16"]
  tags = {
    yor_trace = "bdb6b1ee-f460-490b-b099-e5f4b7c5990d"
  }
}

resource "azurerm_subnet" "test" {
  name                 = "acctestsnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.5.1.0/24"]

  private_link_service_network_policies_enabled = false
}

resource "azurerm_public_ip" "test" {
  name                = "acctestpip"
  sku                 = "Standard"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  allocation_method   = "Static"
  tags = {
    yor_trace = "1fa55d82-f571-4cf1-9018-58eff6671625"
  }
}

resource "azurerm_lb" "test" {
  name                = "acctestlb"
  sku                 = "Standard"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.test.name
    public_ip_address_id = azurerm_public_ip.test.id
  }
  tags = {
    yor_trace = "0fb1bd8e-2181-4c34-bed0-7ff5da10870d"
  }
}

resource "azurerm_private_link_service" "test" {
  name                = "acctestpls"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  nat_ip_configuration {
    name               = azurerm_public_ip.test.name
    subnet_id          = azurerm_subnet.test.id
    private_ip_address = "10.5.1.17"
    primary            = true
  }

  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.test.frontend_ip_configuration.0.id
  ]

  tags = {
    env       = "test"
    yor_trace = "8021c5d3-6323-4899-af3d-29b72d282c25"
  }
}
