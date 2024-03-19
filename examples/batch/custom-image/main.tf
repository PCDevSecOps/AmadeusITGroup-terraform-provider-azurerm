# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    yor_trace = "a4703f34-e3d2-4a43-a668-cf21bb679216"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "batch-custom-img-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    yor_trace = "f93e4b22-e1b3-4f35-b834-335de5931f2b"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "batch-custom-img-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
  domain_name_label   = "batch-custom-img"
  tags = {
    yor_trace = "646e07f0-cee3-4c93-b0d3-8e3e82f06825"
  }
}

resource "azurerm_network_interface" "example" {
  name                = "batch-custom-img-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "exampleconfigurationsource"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
  tags = {
    yor_trace = "84bb7af4-a0cc-4148-aa9c-a2ddf446149e"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "batchcustomimgstore"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Dev"
    yor_trace   = "c93e2b88-f251-4a15-9be6-6c2c78529a1c"
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "blob"
}

resource "azurerm_virtual_machine" "example" {
  name                  = "batch-custom-img-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = ["${azurerm_network_interface.example.id}"]
  vm_size               = "Standard_D1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.example.primary_blob_endpoint}${azurerm_storage_container.example.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
    disk_size_gb  = "30"
  }

  os_profile {
    computer_name  = "batch-custom-img-vm"
    admin_username = "tfuser"
    admin_password = "P@ssW0RD7890"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "Dev"
    cost-center = "Ops"
    yor_trace   = "48cc3193-2d80-48ed-ad5e-3c1038dae315"
  }
}

resource "azurerm_image" "example" {
  name                = "batch-custom-img"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = azurerm_virtual_machine.example.storage_os_disk.0.vhd_uri
    size_gb  = 30
    caching  = "None"
  }

  tags = {
    environment = "Dev"
    cost-center = "Ops"
    yor_trace   = "f1833997-9f1f-42b6-ae0c-07c810f19ba7"
  }
}
resource "azurerm_batch_account" "example" {
  name                = "${var.prefix}batch"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tags = {
    yor_trace = "1dd3d33b-0222-4262-9c14-9debcaee1c92"
  }
}

resource "azurerm_batch_pool" "example" {
  name                = "${var.prefix}-custom-img-pool"
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_batch_account.example.name
  display_name        = "Custom Img Pool"
  vm_size             = "Standard_A1"
  node_agent_sku_id   = "batch.node.ubuntu 22.04"

  fixed_scale {
    target_dedicated_nodes = 2
    resize_timeout         = "PT15M"
  }

  storage_image_reference {
    id = azurerm_image.example.id
  }
}
