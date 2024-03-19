# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "azurerm_key_vault" "example" {
  name                = "${var.prefix}examplekv"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  enabled_for_deployment = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Create",
      "Delete",
      "Get",
      "List",
      "Update",
    ]

    key_permissions = [
      "Create",
    ]

    secret_permissions = [
      "Set",
    ]

    storage_permissions = [
      "Set",
    ]
  }
  tags = {
    yor_trace = "519202ae-c76a-4ac4-91c6-4d096e1de999"
  }
}

resource "azurerm_key_vault_certificate" "example" {
  name         = "${var.prefix}acctestcert"
  key_vault_id = azurerm_key_vault.example.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = [
        "1.3.6.1.5.5.7.3.1",
        "1.3.6.1.5.5.7.3.2",
      ]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=${var.prefix}servicefabric.${var.location}.cloudapp.azure.com"
      validity_in_months = 12
    }
  }
  tags = {
    yor_trace = "b3d8e4e3-d73d-4b5d-813c-25d69a7244bd"
  }
}
