# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = var.location
  tags = {
    yor_trace = "1b32ccd4-39c9-4333-a6f1-ee18efcecf26"
  }
}

# Virtual Machine Resources

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "d6b4232e-d7fe-4e5a-b0dd-5fe4a8abe5b0"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "example-ip"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    yor_trace = "3fa23a05-f526-438f-aa02-436ab1903bf4"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"
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
  tags = {
    yor_trace = "cfee20e2-90ff-4397-a620-2322e9109c90"
  }
}

resource "azurerm_virtual_machine_extension" "example" {
  name                 = "ansible_windows_winrm"
  virtual_machine_id   = azurerm_windows_virtual_machine.example.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"],
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file ConfigureRemotingForAnsible.ps1 -EnableCredSSP -DisableBasicAuth"
    }
SETTINGS
  tags = {
    yor_trace = "859615ab-9a73-4716-8b51-1b60fd3e51ea"
  }
}
