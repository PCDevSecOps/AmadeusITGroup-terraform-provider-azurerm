# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

locals {
  frontend_ip_configuration_name = "internal"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "a6dc81bd-f824-4875-b52d-ab810a0fdf5f"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    yor_trace = "ba1be3ee-8973-4fb8-9eef-5b122e347fb1"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-publicip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  tags = {
    yor_trace = "068aa237-dcc8-47df-a1bd-bcf43b230c13"
  }
}

resource "azurerm_lb" "example" {
  name                = "${var.prefix}lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }
  tags = {
    yor_trace = "8ad7c805-794d-472e-949b-1a22981c4533"
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  name                = "backend"
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
}

resource "azurerm_lb_probe" "example" {
  name                = "ssh-running-probe"
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
  port                = 22
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "example" {
  resource_group_name            = azurerm_resource_group.example.name
  loadbalancer_id                = azurerm_lb.example.id
  probe_id                       = azurerm_lb_probe.example.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.example.id
  frontend_ip_configuration_name = local.frontend_ip_configuration_name
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                 = "${var.prefix}-vmss"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name
  overprovision        = true
  upgrade_policy_mode  = "Rolling"
  automatic_os_upgrade = true
  health_probe_id      = azurerm_lb_probe.example.id

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches              = "PT0S"
  }

  sku {
    name     = "Standard_D1_v2"
    tier     = "Standard"
    capacity = 2
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
    name    = "internal"
    primary = true

    ip_configuration {
      name                                   = "internal"
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.example.id}"]
      primary                                = true
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
    yor_trace = "843d02e5-4e87-447d-b7c0-b989d0064dbb"
  }
}
