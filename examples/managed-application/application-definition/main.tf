# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_role_definition" "builtin" {
  name = "Contributor"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "8d9c4584-1377-477b-bf20-57b4b797d149"
  }
}

resource "azurerm_managed_application_definition" "example" {
  name                = "${var.prefix}managedappdef"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  lock_level          = "ReadOnly"
  package_file_uri    = "https://github.com/Azure/azure-managedapp-samples/raw/master/Managed Application Sample Packages/201-managed-storage-account/managedstorage.zip"
  display_name        = "TestManagedApplicationDefinition"
  description         = "Test Managed Application Definition"

  authorization {
    service_principal_id = data.azurerm_client_config.current.object_id
    role_definition_id   = split("/", data.azurerm_role_definition.builtin.id)[length(split("/", data.azurerm_role_definition.builtin.id)) - 1]
  }
  tags = {
    yor_trace = "b93770f4-bebb-4670-8cd7-eea7f7b6bc49"
  }
}
