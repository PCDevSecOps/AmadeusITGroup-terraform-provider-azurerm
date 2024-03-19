# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

locals {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+wWK73dCr+jgQOAxNsHAnNNNMEMWOHYEccp6wJm2gotpr9katuF/ZAdou5AaW1C61slRkHRkpRRX9FA9CYBiitZgvCCz+3nWNN7l/Up54Zps/pHWGZLHNJZRYyAB6j5yVLMVHIHriY49d/GZTZVNB8GoJv9Gakwc/fuEZYYl4YDFiGMBP///TzlI4jhiJzjKnEvqPFki5p2ZRJqcbCiF4pJrxUQR/RXqVFQdbRLZgYfJ8xGB878RENq3yQ39d8dVOkq4edbkzwcUmwwwkYVPIoDGsYLaRHnG+To7FvMeyO7xDVQkMKzopTQV8AuKpyvpqu0a9pWOMaiCyDytO7GGN you@me.com"
}

resource "azurerm_resource_group" "primary" {
  name     = "${var.prefix}-resources-primary"
  location = var.location
  tags = {
    yor_trace = "7ee4be1a-40b6-4288-80a6-20819d141ffb"
  }
}

resource "azurerm_resource_group" "secondary" {
  name     = "${var.prefix}-resources-secondary"
  location = var.location
  tags = {
    yor_trace = "a235cb92-18a5-42cf-a0f6-c8d01b0cbf64"
  }
}

// Source Vritual Machine
resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.primary.name
  address_space       = ["192.168.1.0/24"]
  location            = azurerm_resource_group.primary.location
  tags = {
    yor_trace = "d95b3583-ed34-4bcd-ad24-d1d27e3747dc"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}subnet"
  resource_group_name  = azurerm_resource_group.primary.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  ip_configuration {
    name                          = "${var.prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    yor_trace = "7a6660e0-2334-4dd2-becf-c9f9c10a7489"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "${var.prefix}-src-vm"
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  zone = "1"
  tags = {
    yor_trace = "6f780c6f-743a-4a46-bc7f-bae148bb64ec"
  }
}

data "azurerm_managed_disk" "os_disk" {
  name                = azurerm_windows_virtual_machine.example.os_disk[0].name
  resource_group_name = azurerm_windows_virtual_machine.example.resource_group_name
}

// Recovery Service
resource "azurerm_recovery_services_vault" "example" {
  name                = "${var.prefix}-recovery-vault"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  sku                 = "Standard"
  soft_delete_enabled = false
  tags = {
    yor_trace = "6e67d37c-80ac-4c3b-a807-7186348ec26e"
  }
}

resource "azurerm_site_recovery_fabric" "example" {
  name                = "${var.prefix}-fabric"
  resource_group_name = azurerm_resource_group.secondary.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name
  location            = azurerm_resource_group.primary.location
}

resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "${var.prefix}-container-primary"
  resource_group_name  = azurerm_resource_group.secondary.name
  recovery_vault_name  = azurerm_recovery_services_vault.example.name
  recovery_fabric_name = azurerm_site_recovery_fabric.example.name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  name                 = "${var.prefix}-container-secondary"
  resource_group_name  = azurerm_resource_group.secondary.name
  recovery_vault_name  = azurerm_recovery_services_vault.example.name
  recovery_fabric_name = azurerm_site_recovery_fabric.example.name
}

resource "azurerm_site_recovery_replication_policy" "example" {
  name                                                 = "${var.prefix}-policy"
  resource_group_name                                  = azurerm_resource_group.secondary.name
  recovery_vault_name                                  = azurerm_recovery_services_vault.example.name
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 4 * 60
}

resource "azurerm_site_recovery_protection_container_mapping" "example" {
  name                                      = "${var.prefix}-container-mapping"
  resource_group_name                       = azurerm_resource_group.secondary.name
  recovery_vault_name                       = azurerm_recovery_services_vault.example.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.example.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.example.id
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}storage"
  location                 = azurerm_resource_group.primary.location
  resource_group_name      = azurerm_resource_group.primary.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    yor_trace = "e60e82d9-d352-458f-8b3c-bbb11d811094"
  }
}

resource "azurerm_site_recovery_replicated_vm" "example" {
  name                                      = "${var.prefix}-rep-vm"
  resource_group_name                       = azurerm_resource_group.secondary.name
  recovery_vault_name                       = azurerm_recovery_services_vault.example.name
  source_vm_id                              = azurerm_windows_virtual_machine.example.id
  source_recovery_fabric_name               = azurerm_site_recovery_fabric.example.name
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.example.id
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  target_resource_group_id                  = azurerm_resource_group.secondary.id
  target_recovery_fabric_id                 = azurerm_site_recovery_fabric.example.id
  target_recovery_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
  target_network_id                         = azurerm_virtual_network.example.id
  target_zone                               = "2"

  managed_disk {
    disk_id                    = data.azurerm_managed_disk.os_disk.id
    staging_storage_account_id = azurerm_storage_account.example.id
    target_resource_group_id   = azurerm_resource_group.secondary.id
    target_disk_type           = "Premium_LRS"
    target_replica_disk_type   = "Premium_LRS"
  }

  network_interface {
    source_network_interface_id = azurerm_network_interface.example.id
    target_subnet_name          = azurerm_subnet.example.name
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.example,
  ]
}
