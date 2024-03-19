# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "ca9aae2a-9a22-405c-a0f1-740e61e3cabd"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "7f6581c7-1311-4e63-a317-388c1d0112a2"
  }
}

resource "azurerm_subnet" "service" {
  name                 = "service"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  private_endpoint_network_policies_enabled = false
}

resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-pip"
  sku                 = "Standard"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  tags = {
    yor_trace = "a6c5a9a0-c6e1-4daf-9448-b1383e496d38"
  }
}

resource "azurerm_lb" "example" {
  name                = "${var.prefix}-lb"
  sku                 = "Standard"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.example.name
    public_ip_address_id = azurerm_public_ip.example.id
  }
  tags = {
    yor_trace = "fe17ec21-cc99-40c9-a7fd-4da844a95196"
  }
}

resource "azurerm_private_link_service" "example" {
  name                = "${var.prefix}-pls"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  auto_approval_subscription_ids = [data.azurerm_subscription.current.subscription_id]
  visibility_subscription_ids    = [data.azurerm_subscription.current.subscription_id]

  nat_ip_configuration {
    name      = azurerm_public_ip.example.name
    subnet_id = azurerm_subnet.service.id
    primary   = true
  }

  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.example.frontend_ip_configuration.0.id]
  tags = {
    yor_trace = "b72293f1-7803-475e-9b1a-8f628e2cedf4"
  }
}

resource "azurerm_private_endpoint" "example" {
  name                = "${var.prefix}-pe"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "tfex-pls-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_private_link_service.example.id
  }
  tags = {
    yor_trace = "45fdfb5b-5b2d-4fbd-bb55-dd981e5bc647"
  }
}
