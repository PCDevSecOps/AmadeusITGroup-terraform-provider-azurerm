# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "8c2090f3-c3fb-4f40-a705-4000f28d586a"
  }
}

resource "azurerm_storage_account" "stor" {
  name                     = "${var.prefix}stor"
  location                 = azurerm_resource_group.example.location
  resource_group_name      = azurerm_resource_group.example.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    yor_trace = "325a639a-b954-4577-b2bb-1db7944fa6eb"
  }
}

resource "azurerm_cdn_profile" "example" {
  name                = "${var.prefix}-cdn"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard_Akamai"
  tags = {
    yor_trace = "e97f86b1-991d-4d0a-bfe3-ff77b6db0a6c"
  }
}

resource "azurerm_cdn_endpoint" "example" {
  name                = "${var.prefix}-cdn"
  profile_name        = azurerm_cdn_profile.example.name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  origin {
    name       = "${var.prefix}origin1"
    host_name  = "www.contoso.com"
    http_port  = 80
    https_port = 443
  }
  tags = {
    yor_trace = "1bec0b39-6773-498a-81c8-2949d2d87b4e"
  }
}
