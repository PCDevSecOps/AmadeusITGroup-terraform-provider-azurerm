# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
  tags = {
    yor_trace = "e90102a0-4a89-4534-8318-80c44b664841"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.hostname}vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["${var.address_space}"]
  tags = {
    yor_trace = "00320760-4fa2-496b-8ce3-94e40d2d52ab"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.hostname}subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.subnet_prefix}"]
}

resource "azurerm_public_ip" "transferpip" {
  name                = "transferpip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags = {
    yor_trace = "10232afd-723a-4b9e-82a5-a560d6b48b4d"
  }
}

resource "azurerm_network_interface" "transfernic" {
  name                = "transfernic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = azurerm_public_ip.transferpip.name
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.transferpip.id
    private_ip_address            = "10.0.0.5"
  }
  tags = {
    yor_trace = "0ef52df1-5660-4e22-aa54-abefc3671b15"
  }
}

resource "azurerm_public_ip" "mypip" {
  name                = "mypip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags = {
    yor_trace = "a0c775b1-3ee0-4950-9932-763597a11d41"
  }
}

resource "azurerm_network_interface" "mynic" {
  name                = "mynic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = azurerm_public_ip.mypip.name
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypip.id
  }
  tags = {
    yor_trace = "3d1c93b7-f304-4b27-b561-c3100b192a8d"
  }
}

resource "azurerm_storage_account" "existing" {
  name                     = var.existing_storage_acct
  resource_group_name      = var.existing_resource_group
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_existing_account_tier
  account_replication_type = var.storage_existing_replication_type

  lifecycle = {
    prevent_destroy = true
  }
  tags = {
    yor_trace = "2c93f0d5-4637-43f0-8ccf-d913b1a2248c"
  }
}

resource "azurerm_storage_account" "stor" {
  name                     = var.hostname
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_machine_account_tier
  account_replication_type = var.storage_machine_replication_type
  tags = {
    yor_trace = "7d654d78-68d8-4f6c-9946-5f0a90720d8c"
  }
}

resource "azurerm_virtual_machine" "transfer" {
  name                  = var.transfer_vm_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  vm_size               = var.vm_size
  network_interface_ids = ["${azurerm_network_interface.transfernic.id}"]

  storage_os_disk {
    name          = "${var.hostname}-osdisk"
    image_uri     = var.source_img_uri
    vhd_uri       = "https://${var.existing_storage_acct}.blob.core.windows.net/${var.existing_resource_group}-vhds/${var.hostname}osdisk.vhd"
    os_type       = var.os_type
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = var.hostname
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  tags = {
    yor_trace = "1c703a69-ab2b-41fc-8d56-2106132c3007"
  }
}

resource "azurerm_virtual_machine_extension" "script" {
  name                 = "CustomScriptExtension"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_machine_name = azurerm_virtual_machine.transfer.name
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.4"
  depends_on           = ["azurerm_virtual_machine.transfer"]

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-custom-image-new-storage-account/ImageTransfer.ps1 -OutFile C:/ImageTransfer.ps1\" "
    }
SETTINGS
  tags = {
    yor_trace = "31982755-3d14-4941-82f2-8b578885a9b1"
  }
}

resource "azurerm_virtual_machine_extension" "execute" {
  name                 = "CustomScriptExtension"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_machine_name = azurerm_virtual_machine.transfer.name
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.4"
  depends_on           = ["azurerm_virtual_machine_extension.script"]

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File C:\\ImageTransfer.ps1 -SourceImage ${var.source_img_uri} -SourceSAKey ${azurerm_storage_account.existing.primary_access_key} -DestinationURI https://${azurerm_storage_account.stor.name}.blob.core.windows.net/vhds -DestinationSAKey ${azurerm_storage_account.stor.primary_access_key}\" "
    }
SETTINGS
  tags = {
    yor_trace = "8dc1d1de-3bb4-4c98-ba9e-323b05189118"
  }
}

resource "azurerm_virtual_machine" "myvm" {
  name                  = var.new_vm_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  vm_size               = var.vm_size
  network_interface_ids = ["${azurerm_network_interface.mynic.id}"]
  depends_on            = ["azurerm_virtual_machine_extension.execute"]

  storage_os_disk {
    name          = "${var.hostname}osdisk"
    image_uri     = "https://${azurerm_storage_account.stor.name}.blob.core.windows.net/vhds/${var.custom_image_name}.vhd"
    vhd_uri       = "https://${var.hostname}.blob.core.windows.net/${var.hostname}-vhds/${var.hostname}osdisk.vhd"
    os_type       = var.os_type
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = var.hostname
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  tags = {
    yor_trace = "fad53a2b-4957-45b2-9688-c9223e0e2fa8"
  }
}
