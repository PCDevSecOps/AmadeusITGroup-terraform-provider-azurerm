# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

data "azurerm_databricks_workspace_private_endpoint_connection" "example" {
  workspace_id        = azurerm_databricks_workspace.example.id
  private_endpoint_id = azurerm_private_endpoint.databricks.id
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-databricks-private-endpoint"
  location = "eastus2"
  tags = {
    yor_trace = "d1ac252a-d0b1-4f9f-ada5-d3d6dc08b1d0"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet-databricks"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "0f851308-daef-448d-8a40-36b3d00f4b2b"
  }
}

resource "azurerm_subnet" "public" {
  name                 = "${var.prefix}-sn-public"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "databricks-del-pub-${var.prefix}"

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
  name                 = "${var.prefix}-sn-private"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "databricks-del-pri-${var.prefix}"

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

resource "azurerm_subnet" "endpoint" {
  name                 = "${var.prefix}-sn-private-endpoint"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.3.0/24"]

  private_endpoint_network_policies_enabled = false
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
  name                = "${var.prefix}-nsg-databricks"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "de0e71b2-7f9e-4e8f-9978-bfee110c2c3f"
  }
}

resource "azurerm_databricks_workspace" "example" {
  name                        = "${var.prefix}-DBW"
  resource_group_name         = azurerm_resource_group.example.name
  location                    = azurerm_resource_group.example.location
  sku                         = "premium"
  managed_resource_group_name = "${var.prefix}-DBW-managed-private-endpoint"

  public_network_access_enabled         = false
  network_security_group_rules_required = "NoAzureDatabricksRules"

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
    Pricing     = "Premium"
    yor_trace   = "07ba9f36-6396-430c-a51d-e7adfc1e061a"
  }
}

resource "azurerm_private_endpoint" "databricks" {
  name                = "${var.prefix}-pe-databricks"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "${var.prefix}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_databricks_workspace.example.id
    subresource_names              = ["databricks_ui_api"]
  }
  tags = {
    yor_trace = "c869f600-dc65-4e84-b288-20255dd1016c"
  }
}

resource "azurerm_private_dns_zone" "example" {
  depends_on = [azurerm_private_endpoint.databricks]

  name                = "privatelink.azuredatabricks.net"
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "007943da-8fa7-4f9a-adf7-6bcebe3befc4"
  }
}

resource "azurerm_private_dns_cname_record" "example" {
  name                = azurerm_databricks_workspace.example.workspace_url
  zone_name           = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 300
  record              = "eastus2-c2.azuredatabricks.net"
  tags = {
    yor_trace = "f5919d55-7851-47e7-8d10-bc9de272782b"
  }
}

output "databricks_workspace_private_endpoint_connection_workspace_id" {
  value = data.azurerm_databricks_workspace_private_endpoint_connection.example.workspace_id
}

output "databricks_workspace_private_endpoint_connection_private_endpoint_id" {
  value = data.azurerm_databricks_workspace_private_endpoint_connection.example.private_endpoint_id
}

output "databricks_workspace_private_endpoint_connection_name" {
  value = data.azurerm_databricks_workspace_private_endpoint_connection.example.connections.0.name
}

output "databricks_workspace_private_endpoint_connection_workspace_private_endpoint_id" {
  value = data.azurerm_databricks_workspace_private_endpoint_connection.example.connections.0.workspace_private_endpoint_id
}

output "databricks_workspace_private_endpoint_connection_status" {
  value = data.azurerm_databricks_workspace_private_endpoint_connection.example.connections.0.status
}

output "databricks_workspace_private_endpoint_connection_description" {
  value = data.azurerm_databricks_workspace_private_endpoint_connection.example.connections.0.description
}

output "databricks_workspace_private_endpoint_connection_action_required" {
  value = data.azurerm_databricks_workspace_private_endpoint_connection.example.connections.0.action_required
}