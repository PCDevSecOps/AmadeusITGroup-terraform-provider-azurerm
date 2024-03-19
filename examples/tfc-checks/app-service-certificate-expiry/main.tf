# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "06c63246-68d6-49c5-8ed5-6b784e1f285c"
  }
}

resource "azurerm_key_vault" "example" {
  name                = "${var.prefix}-key-vault"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
  tags = {
    yor_trace = "152136ed-85ad-45f1-b932-efccda82edb1"
  }
}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.example.id

  tenant_id = azurerm_key_vault.example.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Get",
    "Import"
  ]
}

data "azuread_service_principal" "web_app_resource_provider" {
  application_id = "abfa0a7c-a6b6-4736-8310-5855508787cd"
}

resource "azurerm_key_vault_access_policy" "web_app_resource_provider" {
  key_vault_id = azurerm_key_vault.example.id

  tenant_id = azurerm_key_vault.example.tenant_id
  object_id = data.azuread_service_principal.web_app_resource_provider.id

  secret_permissions = [
    "Get"
  ]

  certificate_permissions = [
    "Get"
  ]
}

resource "azurerm_key_vault_certificate" "example" {
  name         = "${var.prefix}-cert"
  key_vault_id = azurerm_key_vault.example.id

  certificate {
    contents = filebase64("certificate.pfx")
    password = "terraform"
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }

  depends_on = [
    azurerm_key_vault_access_policy.current_user
  ]
  tags = {
    yor_trace = "ebf8bbc7-477c-4f6a-a10b-96c8a4d6c1e1"
  }
}

resource "azurerm_app_service_certificate" "example" {
  name                = "${var.prefix}-cert"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  key_vault_secret_id = azurerm_key_vault_certificate.example.secret_id
  tags = {
    yor_trace = "d49d4776-9478-4a21-b4a4-0422d498cc8a"
  }
}


locals {
  month_in_hour_duration            = "${24 * 30}h"
  month_and_2min_in_second_duration = "${(60 * 60 * 24 * 30) + (60 * 2)}s"
}

data "azurerm_app_service_certificate" "example" {
  name                = azurerm_app_service_certificate.example.name
  resource_group_name = azurerm_app_service_certificate.example.resource_group_name
}

check "check_certificate_state" {
  assert {
    condition = timecmp(plantimestamp(), timeadd(
      data.azurerm_app_service_certificate.example.expiration_date,
    "-${local.month_in_hour_duration}")) < 0
    error_message = format("App Service Certificate (%s) is valid for at least 30 days, but is due to expire on `%s`.",
      data.azurerm_app_service_certificate.example.id,
      data.azurerm_app_service_certificate.example.expiration_date
    )
  }
}