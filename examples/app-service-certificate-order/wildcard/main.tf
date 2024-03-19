# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "49ae3e6e-203a-41ad-a47b-01b420cd895b"
  }
}

resource "azurerm_app_service_certificate_order" "test" {
  name                = "${var.prefix}-autoacc"
  location            = "global"
  resource_group_name = azurerm_resource_group.example.name
  distinguished_name  = "CN=*.example.com"
  product_type        = "WildCard"
  tags = {
    yor_trace = "5edf2409-7a40-44c2-be99-8805ba49f45b"
  }
}
