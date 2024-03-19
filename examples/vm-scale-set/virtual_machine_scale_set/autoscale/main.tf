# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

locals {
  instance_count = 2
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "02cce8f1-34a3-4567-9590-1a2e0a2f055d"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    yor_trace = "9d9c5b53-0601-4328-a664-3c3eebff1321"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "${var.prefix}-vmss"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_D1_v2"
    tier     = "Standard"
    capacity = local.instance_count
  }

  os_profile {
    computer_name_prefix = "${var.prefix}-vm"
    admin_username       = "myadmin"
    admin_password       = "Passwword1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "web_ss_net_profile"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = azurerm_subnet.example.id
      primary   = true
    }
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = {
    yor_trace = "c957a848-6e4f-4920-9bec-e0e4d55ea3f1"
  }
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "autoscale-cpu"
  target_resource_id  = azurerm_virtual_machine_scale_set.example.id
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  profile {
    name = "autoscale-cpu"

    capacity {
      default = local.instance_count
      minimum = 0
      maximum = 1000
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 15
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
  tags = {
    yor_trace = "551826d9-cab1-4440-a2b8-d1db4a281ab8"
  }
}
