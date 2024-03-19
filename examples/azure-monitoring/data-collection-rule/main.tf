# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "f036e3b8-83e1-4fde-9ea2-ac511a31c3c2"
  }
}
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${var.prefix}-law"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    yor_trace = "113abdc3-af7d-47a0-994d-836bc9557e65"
  }
}

resource "azurerm_log_analytics_solution" "vminsights" {
  solution_name         = "VMInsights"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  workspace_name        = azurerm_log_analytics_workspace.workspace.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
  tags = {
    yor_trace = "ba4a25b0-025b-425d-8ffc-18006e7a5d02"
  }
}

# Data Collection Rule
resource "azurerm_monitor_data_collection_rule" "rule" {
  name                = "${var.prefix}-dcr"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
      name                  = "destination-log"
    }

    azure_monitor_metrics {
      name = "destination-metrics"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["destination-metrics"]
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf", "Microsoft-WindowsEvent"]
    destinations = ["destination-log"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
      name                          = "VMInsightsPerfCounters"
    }

  }
  depends_on = [
    azurerm_log_analytics_solution.vminsights
  ]
}
resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "289d14f1-425d-4892-b452-682342a8870e"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    yor_trace = "b8cae588-b795-4f31-a35e-0952adb88f4a"
  }
}

resource "azurerm_user_assigned_identity" "example" {
  name                = "${var.prefix}-id"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "098e0afb-779c-41b3-95d7-f9c3f9b5d6f6"
  }
}

#VM
resource "azurerm_windows_virtual_machine" "example" {
  name                = "${var.prefix}-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.example.id]
  }
  tags = {
    yor_trace = "8f384589-2321-429e-9860-5602c0081eff"
  }
}

# Azure Monitor Extension
resource "azurerm_virtual_machine_extension" "azuremonitorwindowsagent" {
  name                       = "AzureMonitorWindowsAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = 1.8
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = "true"
  virtual_machine_id         = azurerm_windows_virtual_machine.example.id

  settings = jsonencode({
    workspaceId               = azurerm_log_analytics_workspace.workspace.id
    azureResourceId           = azurerm_windows_virtual_machine.example.id
    stopOnMultipleConnections = false

    authentication = {
      managedIdentity = {
        identifier-name  = "mi_res_id"
        identifier-value = azurerm_user_assigned_identity.example.id
      }
    }
  })
  protected_settings = jsonencode({
    "workspaceKey" = azurerm_log_analytics_workspace.workspace.primary_shared_key
  })
  tags = {
    yor_trace = "6df4de1f-f64e-4488-874f-cd78368c7da8"
  }
}

resource "azurerm_virtual_machine_extension" "da" {
  name                       = "DAExtension"
  virtual_machine_id         = azurerm_windows_virtual_machine.example.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.10"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  tags = {
    yor_trace = "7bef6c38-43e7-42b8-9e27-53d91acf1fa5"
  }
}

resource "azurerm_monitor_data_collection_rule_association" "example1" {
  name                    = "${var.prefix}-dcra"
  target_resource_id      = azurerm_windows_virtual_machine.example.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.rule.id
  description             = "example"
}
