# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "b7a4488e-5b80-4ebb-b258-ce910c1362a0"
  }
}

resource "azurerm_container_group" "example" {
  name                = "${var.prefix}-continst"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  ip_address_type     = "Public"
  os_type             = "Linux"

  image_registry_credential {
    server   = "hub.docker.com"
    username = "yourusername1"
    password = "yourpassword"
  }

  image_registry_credential {
    server   = "2hub.docker.com"
    username = "2yourusername1"
    password = "2yourpassword"
  }

  container {
    name   = "hw"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  container {
    name   = "sidecar"
    image  = "mcr.microsoft.com/azuredocs/aci-tutorial-sidecar"
    cpu    = "0.5"
    memory = "1.5"
  }

  tags = {
    environment = "testing"
    yor_trace   = "6460128a-6aac-4ea0-958e-f06e4053b320"
  }
}
