# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-k8s-resources"
  location = var.location
  tags = {
    yor_trace = "2aa18f53-6a8e-4a27-ad01-6d46e545f4d1"
  }
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.prefix}-law"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "PerGB2018"
  tags = {
    yor_trace = "d3132a33-2588-4c99-aab3-8209f1d0d8a1"
  }
}

resource "azurerm_log_analytics_solution" "example" {
  solution_name         = "Containers"
  workspace_resource_id = azurerm_log_analytics_workspace.example.id
  workspace_name        = azurerm_log_analytics_workspace.example.name
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
  tags = {
    yor_trace = "e33b7fa3-d994-4a39-a1dd-dc25de8662bc"
  }
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "${var.prefix}-k8s"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "${var.prefix}-k8s"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.example.id
    msi_auth_for_monitoring_enabled = true
  }
  tags = {
    yor_trace = "24edc94d-aa3a-43df-af35-3eacd86f6ac0"
  }
}
