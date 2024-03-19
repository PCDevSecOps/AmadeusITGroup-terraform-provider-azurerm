# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "75a70ce9-8674-474f-82f8-351a114a63f7"
  }
}

resource "azurerm_app_service_certificate_order" "test" {
  name                = "${var.prefix}-autoacc"
  location            = "global"
  resource_group_name = azurerm_resource_group.example.name
  distinguished_name  = "CN=example.com"
  product_type        = "Standard"
  tags = {
    yor_trace = "b12c0929-7c3e-46d3-ade2-6a6f6bfd4419"
  }
}
