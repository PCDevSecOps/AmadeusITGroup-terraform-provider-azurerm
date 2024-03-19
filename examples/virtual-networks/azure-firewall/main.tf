# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "azurg" {
  name     = "rgAzureFirewall"
  location = "East US"
  tags = {
    yor_trace = "ea410f2e-d0fe-42f1-8cc0-af184d4c6205"
  }
}

# generate a random prefix
resource "random_string" "azustring" {
  length  = 16
  special = false
  upper   = false
  number  = false
}

# Storage account to hold diag data from VMs and Azure Resources
resource "azurerm_storage_account" "azusa" {
  name                     = random_string.azustring.result
  resource_group_name      = azurerm_resource_group.azurg.name
  location                 = azurerm_resource_group.azurg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "c3979fe7-e82d-44ed-a3e2-fa3061c91686"
  }
}

# Route Table for Azure Virtual Network and Server Subnet
resource "azurerm_route_table" "azurt" {
  name                          = "AzfwRouteTable"
  resource_group_name           = azurerm_resource_group.azurg.name
  location                      = azurerm_resource_group.azurg.location
  disable_bgp_route_propagation = false

  route {
    name                   = "AzfwDefaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }

  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "5b852ba1-cddf-407f-840b-07e4a59817b8"
  }
}

# Virtual network for azure firewall and servers
resource "azurerm_virtual_network" "azuvnet" {
  name                = "virtualNetwork1"
  resource_group_name = azurerm_resource_group.azurg.name
  location            = azurerm_resource_group.azurg.location
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["168.63.129.16", "8.8.8.8"]

  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "fea0c6a3-4977-4522-8b15-a66d0f60f822"
  }
}

# Subnet for Jumpbox, Servers, and Firewall and Route Table Association
resource "azurerm_subnet" "azusubnetjb" {
  name                 = "JumpboxSubnet"
  resource_group_name  = azurerm_resource_group.azurg.name
  virtual_network_name = azurerm_virtual_network.azuvnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "azusubnetfw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.azurg.name
  virtual_network_name = azurerm_virtual_network.azuvnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "azusubnet" {
  name                 = "ServersSubnet"
  resource_group_name  = azurerm_resource_group.azurg.name
  virtual_network_name = azurerm_virtual_network.azuvnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet_route_table_association" "azurtassoc" {
  subnet_id      = azurerm_subnet.azusubnet.id
  route_table_id = azurerm_route_table.azurt.id
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "azufwpip" {
  name                = "azureFirewalls-ip"
  resource_group_name = azurerm_resource_group.azurg.name
  location            = azurerm_resource_group.azurg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "162c484c-59e8-4ef8-b110-796d03d428ed"
  }
}

# Public IP for Jumpbox
resource "azurerm_public_ip" "azujumppip" {
  name                = "jumpBox-ip"
  resource_group_name = azurerm_resource_group.azurg.name
  location            = azurerm_resource_group.azurg.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"

  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "13d366bd-08f9-4d2c-a839-53ff6e346678"
  }
}

# NSG for JumpBox Server
resource "azurerm_network_security_group" "azunsgjb" {
  name                = "JumpHostNSG"
  resource_group_name = azurerm_resource_group.azurg.name
  location            = azurerm_resource_group.azurg.location

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "c4bd80e6-1da5-41ae-b6e0-ac7a3b1a7c85"
  }
}

# Nic for JumpBox Server
resource "azurerm_network_interface" "azunicjb" {
  name                = "JumpHostNIC"
  resource_group_name = azurerm_resource_group.azurg.name
  location            = azurerm_resource_group.azurg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.azusubnetjb.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azujumppip.id
  }

  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "b95dc8bf-4566-4e2a-8f60-e958492a404a"
  }
}

resource "azurerm_network_interface_security_group_association" "azunicjb" {
  network_interface_id      = azurerm_network_interface.azunicjb.id
  network_security_group_id = azurerm_network_security_group.azunsgjb.id
}

# Nic for Server
resource "azurerm_network_interface" "azunicvm" {
  name                = "ServerNIC"
  resource_group_name = azurerm_resource_group.azurg.name
  location            = azurerm_resource_group.azurg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.azusubnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "6c2c6c39-d1f6-4406-b633-c8f75d6d8d23"
  }
}

# JumpBox VM
resource "azurerm_virtual_machine" "vmjb" {
  name                  = "JumpBox"
  resource_group_name   = azurerm_resource_group.azurg.name
  location              = azurerm_resource_group.azurg.location
  network_interface_ids = ["${azurerm_network_interface.azunicjb.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "JumpBox-OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "JumpBox"
    admin_username = var.adminUsername
    admin_password = var.adminPassword
  }
  os_profile_windows_config {}
  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.azusa.primary_blob_endpoint
  }


  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "9343b859-b56e-4f4f-8faf-3cc13644a6cb"
  }

  depends_on = [azurerm_network_interface_security_group_association.azunicjb]
}

# Server VM
resource "azurerm_virtual_machine" "vmserver" {
  name                  = "Server"
  resource_group_name   = azurerm_resource_group.azurg.name
  location              = azurerm_resource_group.azurg.location
  network_interface_ids = ["${azurerm_network_interface.azunicvm.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "Server-OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "Server"
    admin_username = var.adminUsername
    admin_password = var.adminPassword
  }
  os_profile_windows_config {}
  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.azusa.primary_blob_endpoint
  }


  tags = {
    environment = "Staging"
    owner       = "Someone@contoso.com"
    costcenter  = "IT"
    yor_trace   = "efb949c5-6a3a-4540-8a72-4985e911477a"
  }
}

# Azure Firewall
resource "azurerm_firewall" "azufw" {
  name                = "firewall1"
  resource_group_name = azurerm_resource_group.azurg.name
  location            = azurerm_resource_group.azurg.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.azusubnetfw.id
    public_ip_address_id = azurerm_public_ip.azufwpip.id
  }
  tags = {
    yor_trace = "28864361-6928-4859-af21-89a8075c4e46"
  }
}

# Azure Firewall Application Rule
resource "azurerm_firewall_application_rule_collection" "azufwappr1" {
  name                = "appRc1"
  azure_firewall_name = azurerm_firewall.azufw.name
  resource_group_name = azurerm_resource_group.azurg.name
  priority            = 101
  action              = "Allow"

  rule {
    name = "appRule1"

    source_addresses = [
      "10.0.0.0/24",
    ]

    target_fqdns = [
      "www.microsoft.com",
    ]

    protocol {
      port = "80"
      type = "Http"
    }
  }
}

# Azure Firewall Network Rule
resource "azurerm_firewall_network_rule_collection" "azufwnetr1" {
  name                = "testcollection"
  azure_firewall_name = azurerm_firewall.azufw.name
  resource_group_name = azurerm_resource_group.azurg.name
  priority            = 200
  action              = "Allow"

  rule {
    name = "netRc1"

    source_addresses = [
      "10.0.0.0/24",
    ]

    destination_ports = [
      "8000-8999",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "TCP",
    ]
  }
}
