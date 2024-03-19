# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "ae5223ea-0b16-40d0-ae84-a87929302571"
  }
}

resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  tags = {
    yor_trace = "27eaaefa-4b3e-4cc3-aa1f-30a1d6b0c9f2"
  }
}

resource "azurerm_application_security_group" "example" {
  name                = "${var.prefix}-appsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "aac856b7-23dd-4f6f-bd64-555c62a23979"
  }
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfig-ip"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
  tags = {
    yor_trace = "a0be84fc-8b2d-4e2e-9317-c5f1ff024f8c"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  tags = {
    yor_trace = "06b73488-2504-4b1a-81f3-8519e3d9bd09"
  }
}

resource "azurerm_network_interface_application_security_group_association" "example" {
  network_interface_id          = azurerm_network_interface.example.id
  application_security_group_id = azurerm_application_security_group.example.id

  depends_on = [azurerm_linux_virtual_machine.example]
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "67c506ef-e21f-4c01-9b56-71d2169cb193"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/8"]
  tags = {
    yor_trace = "dfa4881c-01cc-4234-ab69-db1863d41174"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_rule" "example" {
  name                   = "${var.prefix}-nsgrule"
  priority               = 230
  direction              = "Inbound"
  access                 = "Deny"
  protocol               = "Tcp"
  source_port_range      = "*"
  destination_port_range = "22"
  source_address_prefix  = "Internet"

  destination_application_security_group_ids = [
    azurerm_application_security_group.example.id
  ]

  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}
