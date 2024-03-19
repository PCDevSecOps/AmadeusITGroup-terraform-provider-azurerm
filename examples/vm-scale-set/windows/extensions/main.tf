# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "90065d86-ba68-4d18-a3d5-8b63d1d08e2f"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    yor_trace = "827b7d71-a2d1-487c-a1ba-f19552b70513"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_windows_virtual_machine_scale_set" "main" {
  name                 = "${var.prefix}vmss"
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  sku                  = "Standard_F2"
  instances            = 3
  admin_username       = "adminuser"
  admin_password       = "P@ssw0rd1234!"
  computer_name_prefix = var.prefix

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  network_interface {
    name    = "example"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  extension {
    name                       = "CustomScript"
    publisher                  = "Microsoft.Compute"
    type                       = "CustomScriptExtension"
    type_handler_version       = "1.10"
    auto_upgrade_minor_version = true

    settings = jsonencode({ "commandToExecute" = "powershell.exe -c \"Get-Content env:computername\"" })

    protected_settings = jsonencode({ "managedIdentity" = {} })
  }

  extension {
    name                       = "AADLoginForWindows"
    publisher                  = "Microsoft.Azure.ActiveDirectory"
    type                       = "AADLoginForWindows"
    type_handler_version       = "1.0"
    auto_upgrade_minor_version = true
  }

  tags = {
    yor_trace = "67e168ff-9943-4fbc-b139-68664445f338"
  }
}
