# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

## This code demonstrate how to setup Azure Redis Cache monitors

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "example_rg_rediscache"
  location = "east us"
  tags = {
    yor_trace = "b666141f-e45d-447b-930e-daf0ef198d26"
  }
}

resource "azurerm_monitor_action_group" "main" {
  name                = "example-actiongroup"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "exampleact"

  email_receiver {
    name                    = "ishantdevops"
    email_address           = "devops@example.com"
    use_common_alert_schema = true
  }

  webhook_receiver {
    name        = "callmyapi"
    service_uri = "http://example.com/alert"
  }
  tags = {
    yor_trace = "7bf38493-6697-40a4-903c-6990b3f6b160"
  }
}


### Cache Hits Alert
resource "azurerm_monitor_metric_alert" "cache_hit_alert" {
  name                = "${var.cache.service_name} ${var.cache.environment} - Cache Hits Alert"
  resource_group_name = var.cache.cache_name
  scopes              = [var.cache.scope]
  description         = "${var.cache.service_name} Cache Hits Alert"

  criteria {
    metric_namespace = "Microsoft.Cache/redis"
    metric_name      = "cachehits"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.cache.cache_hit_threshold


  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  tags = {
    yor_trace = "6c317ae8-6940-4e7b-9ea9-ae9b45b71629"
  }
}


### Cache Misses Alert
resource "azurerm_monitor_metric_alert" "cache_miss_alert" {
  name                = "${var.cache.service_name} ${var.cache.environment} - Cache Miss Alert"
  resource_group_name = var.cache.cache_name
  scopes              = [var.cache.scope]
  description         = "${var.cache.service_name} - Cache Miss Alert"

  criteria {
    metric_namespace = "Microsoft.Cache/redis"
    metric_name      = "cachemisses"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.cache.cache_misses_threshold


  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  tags = {
    yor_trace = "7f884ab0-57ca-4e71-9130-c370592a545f"
  }
}

### Cache Connection Alert
resource "azurerm_monitor_metric_alert" "cache_connected_clients" {
  name                = "${var.cache.service_name} ${var.cache.environment} - Cache Connected Clients"
  resource_group_name = var.cache.cache_name
  scopes              = [var.cache.scope]
  description         = "${var.cache.service_name} - Cache Connected Clients"

  criteria {
    metric_namespace = "Microsoft.Cache/redis"
    metric_name      = "connectedclients"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.cache.cache_connected_clients_threshold


  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  tags = {
    yor_trace = "bcdaa0eb-8ce0-4599-8a63-46f279fa298f"
  }
}


### Cache CPU Alert
resource "azurerm_monitor_metric_alert" "cache_cpu" {
  name                = "${var.cache.service_name} ${var.cache.environment} - Cache CPU"
  resource_group_name = var.cache.cache_name
  scopes              = [var.cache.scope]
  description         = "${var.cache.service_name} - Cache CPU"

  criteria {
    metric_namespace = "Microsoft.Cache/redis"
    metric_name      = "percentProcessorTime"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.cache.cache_cpu_threshold


  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  tags = {
    yor_trace = "dfd6813d-b18a-45c3-90cc-14cfa7a61ed7"
  }
}
