# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "6a8215cb-b236-41db-8ef0-aeb9c226e68f"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-VN"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "13706bb5-0d61-4ad6-9c8f-a330cbf4a901"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}-SN"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-PIP"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
  tags = {
    yor_trace = "22f87e52-b239-444d-bb0e-59482ad4b76f"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-NSG"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "54cfafe6-b61f-49d8-a6fb-02d235456bff"
  }
}

resource "azurerm_network_security_rule" "RDPRule" {
  name                        = "RDPRule"
  resource_group_name         = azurerm_resource_group.example.name
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = "167.220.255.0/25"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "MSSQLRule" {
  name                        = "MSSQLRule"
  resource_group_name         = azurerm_resource_group.example.name
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 1433
  source_address_prefix       = "167.220.255.0/25"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-NIC"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "exampleconfiguration1"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
  tags = {
    yor_trace = "f0ae5812-d2a5-46c8-8d7b-194af65bbe9c"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_virtual_machine" "example" {
  name                  = "${var.prefix}-VM"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS14_v2"

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "SQLDEV"
    version   = "laexample"
  }

  storage_os_disk {
    name              = "${var.prefix}-OSDisk"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "winhost01"
    admin_username = "exampleadmin"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {
    timezone                  = "Pacific Standard Time"
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
  tags = {
    yor_trace = "836b81cc-d2d6-48ad-8d7a-499247060ef4"
  }
}

resource "azurerm_mssql_virtual_machine" "example" {
  virtual_machine_id = azurerm_virtual_machine.example.id
  sql_license_type   = "PAYG"
  tags = {
    yor_trace = "d7ddb23f-89fd-4b33-a69f-96401953e221"
  }
}

resource "azurerm_virtual_network" "test" {
  name                = "${var.prefix}-VN"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "818c696f-0b75-4e25-8d1e-a746ce7ef026"
  }
}

resource "azurerm_subnet" "test" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "test" {
  name                = "${var.prefix}-PIP"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
  tags = {
    yor_trace = "57efb435-9316-40a3-b4de-4985e8c2ba60"
  }
}

resource "azurerm_network_interface" "test" {
  name                = "${var.prefix}-INT"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test.id
  }
  tags = {
    yor_trace = "e30b234c-f34f-4b93-a0db-1ea4905b72e8"
  }
}

resource "azurerm_virtual_machine" "test" {
  name                  = "${var.prefix}-VM"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.test.id]
  vm_size               = "Standard_F4"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-VM"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {
    timezone           = "Pacific Standard Time"
    provision_vm_agent = true
  }
  tags = {
    yor_trace = "8a21a20a-d745-4efd-ac0f-978606d6b388"
  }
}

resource "azurerm_virtual_machine_extension" "test" {
  name                 = "${var.prefix}-EXT"
  virtual_machine_id   = azurerm_virtual_machine.test.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings = jsonencode({
    "fileUris"         = ["https://raw.githubusercontent.com/Azure/azure-quickstart-templates/00b79d2102c88b56502a63041936ef4dd62cf725/101-vms-with-selfhost-integration-runtime/gatewayInstall.ps1"],
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File gatewayInstall.ps1 ${azurerm_data_factory_integration_runtime_self_hosted.host.primary_authorization_key} && timeout /t 120"
  })
  tags = {
    yor_trace = "489bd6af-258f-4ad4-ad32-c1db46dfdcc0"
  }
}

resource "azurerm_resource_group" "host" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "276e2603-4ff8-4b80-b1cd-6cd668267767"
  }
}

resource "azurerm_data_factory" "host" {
  name                = "${var.prefix}DFHOST"
  location            = azurerm_resource_group.host.location
  resource_group_name = azurerm_resource_group.host.name
  tags = {
    yor_trace = "a1335554-44d9-4f97-af2b-8f610d6f1090"
  }
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "host" {
  name            = "${var.prefix}IRHOST"
  data_factory_id = azurerm_data_factory.host.id
}

resource "azurerm_resource_group" "target" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "9535342c-95b9-40a4-abe8-327e130cbfa7"
  }
}

resource "azurerm_role_assignment" "target" {
  scope                = azurerm_data_factory.host.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.target.identity[0].principal_id
}

resource "azurerm_data_factory" "target" {
  name                = "${var.prefix}DFTGT"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name

  identity {
    type = "SystemAssigned"
  }
  tags = {
    yor_trace = "e91a0935-1d5a-42a4-a6c6-71f3076a5ba7"
  }
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "target" {
  name            = "${var.prefix}IRTGT"
  data_factory_id = azurerm_data_factory.target.id

  rbac_authorization {
    resource_id = azurerm_data_factory_integration_runtime_self_hosted.host.id
  }

  depends_on = [azurerm_role_assignment.target, azurerm_virtual_machine_extension.test]
}
