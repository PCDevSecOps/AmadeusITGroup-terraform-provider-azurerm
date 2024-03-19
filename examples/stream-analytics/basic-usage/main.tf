# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-example-resources"
  location = var.location
  tags = {
    yor_trace = "0e0d0bbd-5aed-447b-8ad1-9d5d6a22e77a"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}examplestoracc"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    yor_trace = "dba238f3-61cf-4e75-9db2-79386fc6e716"
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "${var.prefix}example"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_stream_analytics_job" "example" {
  name                                     = "${var.prefix}-example-job"
  resource_group_name                      = azurerm_resource_group.example.name
  location                                 = azurerm_resource_group.example.location
  compatibility_level                      = "1.1"
  data_locale                              = "en-US"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 3

  tags = {
    environment = "Example"
    yor_trace   = "e9a3836e-27ea-4e82-8c91-0b2e9f7f0ed8"
  }

  transformation_query = <<QUERY
    SELECT *
    INTO [YourOutputAlias]
    FROM [YourInputAlias]
QUERY
}

resource "azurerm_stream_analytics_reference_input_blob" "test" {
  name                      = "${var.prefix}-blob-reference-input"
  stream_analytics_job_name = azurerm_stream_analytics_job.example.name
  resource_group_name       = azurerm_stream_analytics_job.example.resource_group_name
  storage_account_name      = azurerm_storage_account.example.name
  storage_account_key       = azurerm_storage_account.example.primary_access_key
  storage_container_name    = azurerm_storage_container.example.name
  path_pattern              = "some-random-pattern"
  date_format               = "yyyy/MM/dd"
  time_format               = "HH"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}
