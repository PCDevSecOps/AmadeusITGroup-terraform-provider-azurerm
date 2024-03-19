# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-databrick-connectivity-with-lb"
  location = "eastus2"
  tags = {
    yor_trace = "c05771d1-a091-4d6c-9296-529b2f568490"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-databricks-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "02cfcd4c-6f10-4b7f-b9d6-55b800899cb7"
  }
}

resource "azurerm_subnet" "public" {
  name                 = "${var.prefix}-public-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "${var.prefix}-databricks-del"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet" "private" {
  name                 = "${var.prefix}-private-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "${var.prefix}-databricks-del"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-databricks-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "09b6278f-a194-4181-bee6-e092efc3909f"
  }
}

resource "azurerm_databricks_workspace" "example" {
  name                        = "DBW-${var.prefix}"
  resource_group_name         = azurerm_resource_group.example.name
  location                    = azurerm_resource_group.example.location
  sku                         = "premium"
  managed_resource_group_name = "${var.prefix}-DBW-managed-with-lb"

  public_network_access_enabled         = true
  load_balancer_backend_address_pool_id = azurerm_lb_backend_address_pool.example.id

  custom_parameters {
    no_public_ip        = true
    public_subnet_name  = azurerm_subnet.public.name
    private_subnet_name = azurerm_subnet.private.name
    virtual_network_id  = azurerm_virtual_network.example.id

    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }

  tags = {
    Environment = "Production"
    Pricing     = "Standard"
    yor_trace   = "722bfc33-d2b3-4548-824b-703cd9a46e6d"
  }
}

resource "azurerm_public_ip" "example" {
  name                    = "Databricks-LB-PublicIP"
  location                = azurerm_resource_group.example.location
  resource_group_name     = azurerm_resource_group.example.name
  idle_timeout_in_minutes = 4
  allocation_method       = "Static"

  sku = "Standard"
  tags = {
    yor_trace = "ada785a7-8e23-448b-b1c1-05321787ef97"
  }
}

resource "azurerm_lb" "example" {
  name                = "Databricks-LB"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku = "Standard"

  frontend_ip_configuration {
    name                 = "Databricks-PIP"
    public_ip_address_id = azurerm_public_ip.example.id
  }
  tags = {
    yor_trace = "7e16b127-eb85-4719-8dd2-e63576d18c57"
  }
}

resource "azurerm_lb_outbound_rule" "example" {
  name                = "Databricks-LB-Outbound-Rules"
  resource_group_name = azurerm_resource_group.example.name

  loadbalancer_id          = azurerm_lb.example.id
  protocol                 = "All"
  enable_tcp_reset         = true
  allocated_outbound_ports = 1024
  idle_timeout_in_minutes  = 4

  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id

  frontend_ip_configuration {
    name = azurerm_lb.example.frontend_ip_configuration.0.name
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "Databricks-BE"
}
