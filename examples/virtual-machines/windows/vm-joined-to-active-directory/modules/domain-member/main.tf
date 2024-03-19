# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "azurerm_public_ip" "static" {
  name                = "${var.prefix}-client-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  tags = {
    yor_trace = "803fabf9-55f1-446e-9804-cefa100e94b9"
  }
}

resource "azurerm_network_interface" "primary" {
  name                = "${var.prefix}-client-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.static.id
  }
  tags = {
    yor_trace = "ad225326-bfb8-41f9-895c-db25a1b29317"
  }
}

resource "azurerm_windows_virtual_machine" "domain-member" {
  name                     = local.virtual_machine_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  size                     = "Standard_F2"
  admin_username           = var.admin_username
  admin_password           = var.admin_password
  provision_vm_agent       = true
  enable_automatic_updates = true

  network_interface_ids = [
    azurerm_network_interface.primary.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  tags = {
    yor_trace = "48d5a41c-6c1e-44b6-8612-f040da6b0859"
  }
}

// Waits for up to 1 hour for the Domain to become available. Will return an error 1 if unsuccessful preventing the member attempting to join.
// todo - find out why this is so variable? (approx 40min during testing)

resource "azurerm_virtual_machine_extension" "wait-for-domain-to-provision" {
  name                 = "TestConnectionDomain"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  virtual_machine_id   = azurerm_windows_virtual_machine.domain-member.id
  settings             = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -Command \"while (!(Test-Connection -ComputerName ${var.active_directory_domain_name} -Count 1 -Quiet) -and ($retryCount++ -le 360)) { Start-Sleep 10 } \""
  }
SETTINGS
  tags = {
    yor_trace = "a9c495c1-9e5c-4f3d-a699-f64a5390802a"
  }
}

resource "azurerm_virtual_machine_extension" "join-domain" {
  name                 = azurerm_windows_virtual_machine.domain-member.name
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  virtual_machine_id   = azurerm_windows_virtual_machine.domain-member.id

  settings = <<SETTINGS
    {
        "Name": "${var.active_directory_domain_name}",
        "OUPath": "",
        "User": "${var.active_directory_username}@${var.active_directory_domain_name}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<SETTINGS
    {
        "Password": "${var.active_directory_password}"
    }
SETTINGS

  depends_on = [azurerm_virtual_machine_extension.wait-for-domain-to-provision]
  tags = {
    yor_trace = "17356ef8-116a-49b3-90d6-12ce808fae04"
  }
}
