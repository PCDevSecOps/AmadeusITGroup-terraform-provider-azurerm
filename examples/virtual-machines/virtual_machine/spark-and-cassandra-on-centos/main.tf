# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
  tags = {
    yor_trace = "e9da8246-e0ce-4386-b87e-b69ce5773778"
  }
}

# **********************  NETWORK SECURITY GROUPS ********************** #
resource "azurerm_network_security_group" "primary" {
  name                = var.nsg_spark_primary_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "ssh"
    description                = "Allow SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http_webui_spark"
    description                = "Allow Web UI Access to Spark"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http_rest_spark"
    description                = "Allow REST API Access to Spark"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6066"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    yor_trace = "bb5569d4-d4b9-405a-b64d-f1a26727d64a"
  }
}

resource "azurerm_network_security_group" "secondary" {
  name                = var.nsg_spark_secondary_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "ssh"
    description                = "Allow SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    yor_trace = "3ca1d656-2a71-4d9d-ba2f-17bbd154d7dc"
  }
}

resource "azurerm_network_security_group" "cassandra" {
  name                = var.nsg_cassandra_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "ssh"
    description                = "Allow SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    yor_trace = "237fb75a-44bf-4496-a667-3294c1bf0c01"
  }
}

# **********************  VNET / SUBNETS ********************** #
resource "azurerm_virtual_network" "spark" {
  name                = "vnet-spark"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["${var.vnet_spark_prefix}"]
  tags = {
    yor_trace = "7092b6d9-65e5-436b-80ba-553a94cbf734"
  }
}

resource "azurerm_subnet" "subnet1" {
  name                      = var.vnet_spark_subnet1_name
  virtual_network_name      = azurerm_virtual_network.spark.name
  resource_group_name       = azurerm_resource_group.rg.name
  address_prefixes          = ["${var.vnet_spark_subnet1_prefix}"]
  network_security_group_id = azurerm_network_security_group.primary.id
  depends_on                = ["azurerm_virtual_network.spark"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = var.vnet_spark_subnet2_name
  virtual_network_name = azurerm_virtual_network.spark.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.vnet_spark_subnet2_prefix}"]
}

resource "azurerm_subnet" "subnet3" {
  name                 = var.vnet_spark_subnet3_name
  virtual_network_name = azurerm_virtual_network.spark.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.vnet_spark_subnet3_prefix}"]
}

# **********************  PUBLIC IP ADDRESSES ********************** #
resource "azurerm_public_ip" "primary" {
  name                = var.public_ip_primary_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags = {
    yor_trace = "8246e253-73c4-4f0d-a428-4a2f9bcaadce"
  }
}

resource "azurerm_public_ip" "secondary" {
  name                = "${var.public_ip_secondary_name_prefix}${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  count               = var.vm_number_of_secondarys
  tags = {
    yor_trace = "5e7f2bc4-c460-4156-920f-c42494d125e1"
  }
}

resource "azurerm_public_ip" "cassandra" {
  name                = var.public_ip_cassandra_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags = {
    yor_trace = "d3611346-7cca-4ea4-bb85-00b8eff52cff"
  }
}

# **********************  NETWORK INTERFACE ********************** #
resource "azurerm_network_interface" "primary" {
  name                      = var.nic_primary_name
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.primary.id
  depends_on                = ["azurerm_virtual_network.spark", "azurerm_public_ip.primary", "azurerm_network_security_group.primary"]

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.nic_primary_node_ip
    public_ip_address_id          = azurerm_public_ip.primary.id
  }
  tags = {
    yor_trace = "d3406ba8-370f-486d-bcab-e9a3567030ba"
  }
}

resource "azurerm_network_interface" "secondary" {
  name                      = "${var.nic_secondary_name_prefix}${count.index}"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.secondary.id
  count                     = var.vm_number_of_secondarys
  depends_on                = ["azurerm_virtual_network.spark", "azurerm_public_ip.secondary", "azurerm_network_security_group.secondary"]

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.nic_secondary_node_ip_prefix}${5 + count.index}"
    public_ip_address_id          = element(azurerm_public_ip.secondary.*.id, count.index)
  }
  tags = {
    yor_trace = "86e4b4b4-f9a9-4151-89d8-e953f9a8169b"
  }
}

resource "azurerm_network_interface" "cassandra" {
  name                      = var.nic_cassandra_name
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.cassandra.id
  depends_on                = ["azurerm_virtual_network.spark", "azurerm_public_ip.cassandra", "azurerm_network_security_group.cassandra"]

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.nic_cassandra_node_ip
    public_ip_address_id          = azurerm_public_ip.cassandra.id
  }
  tags = {
    yor_trace = "74b7f565-50ba-4fee-9e1f-0c34dcf1b4c3"
  }
}

# **********************  AVAILABILITY SET ********************** #
resource "azurerm_availability_set" "secondary" {
  name                         = var.availability_secondary_name
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_update_domain_count = 5
  platform_fault_domain_count  = 2
  tags = {
    yor_trace = "a487cdee-0b75-4c66-8349-0cab93d54248"
  }
}

# **********************  STORAGE ACCOUNTS ********************** #
resource "azurerm_storage_account" "primary" {
  name                     = "primary${var.unique_prefix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_primary_account_tier
  account_replication_type = var.storage_primary_replication_type
  tags = {
    yor_trace = "753a7dc4-3830-4a29-a493-6fa3e452c187"
  }
}

resource "azurerm_storage_container" "primary" {
  name                  = var.vm_primary_storage_account_container_name
  resource_group_name   = azurerm_resource_group.rg.name
  storage_account_name  = azurerm_storage_account.primary.name
  container_access_type = "private"
  depends_on            = ["azurerm_storage_account.primary"]
}

resource "azurerm_storage_account" "secondary" {
  name                     = "secondary${var.unique_prefix}${count.index}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  count                    = var.vm_number_of_secondarys
  account_tier             = var.storage_secondary_account_tier
  account_replication_type = var.storage_secondary_replication_type
  tags = {
    yor_trace = "9d66de06-ffc0-41fb-be7a-997206588298"
  }
}

resource "azurerm_storage_container" "secondary" {
  name                  = "${var.vm_secondary_storage_account_container_name}${count.index}"
  storage_account_name  = element(azurerm_storage_account.secondary.*.name, count.index)
  container_access_type = "private"
  depends_on            = ["azurerm_storage_account.secondary"]
}

resource "azurerm_storage_account" "cassandra" {
  name                     = "cassandra${var.unique_prefix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_cassandra_account_tier
  account_replication_type = var.storage_cassandra_replication_type
  tags = {
    yor_trace = "e9ea77cb-f92d-49bc-babe-90e28d14ce45"
  }
}

resource "azurerm_storage_container" "cassandra" {
  name                  = var.vm_cassandra_storage_account_container_name
  storage_account_name  = azurerm_storage_account.cassandra.name
  container_access_type = "private"
  depends_on            = ["azurerm_storage_account.cassandra"]
}

# ********************** PRIMARY VIRTUAL MACHINE ********************** #
resource "azurerm_virtual_machine" "primary" {
  name                  = var.vm_primary_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  vm_size               = var.vm_primary_vm_size
  network_interface_ids = ["${azurerm_network_interface.primary.id}"]
  depends_on            = ["azurerm_storage_account.primary", "azurerm_network_interface.primary", "azurerm_storage_container.primary"]

  storage_image_reference {
    publisher = var.os_image_publisher
    offer     = var.os_image_offer
    sku       = var.os_version
    version   = "latest"
  }

  storage_os_disk {
    name          = var.vm_primary_os_disk_name
    vhd_uri       = "http://${azurerm_storage_account.primary.name}.blob.core.windows.net/${azurerm_storage_container.primary.name}/${var.vm_primary_os_disk_name}.vhd"
    create_option = "FromImage"
    caching       = "ReadWrite"
  }

  os_profile {
    computer_name  = var.vm_primary_name
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
    type     = "ssh"
    host     = azurerm_public_ip.primary.ip_address
    user     = var.vm_admin_username
    password = var.vm_admin_password
  }

  provisioner "remote-exec" {
    inline = [
      "wget ${var.artifacts_location}${var.script_spark_provisioner_script_file_name}",
      "echo ${var.vm_admin_password} | sudo -S sh ./${var.script_spark_provisioner_script_file_name} -runas=primary -primary=${var.nic_primary_node_ip}",
    ]
  }
  tags = {
    yor_trace = "d9fb0921-c831-4937-91c2-701a57ea5b93"
  }
}

# ********************** SECONDARY VIRTUAL MACHINES ********************** #
resource "azurerm_virtual_machine" "secondary" {
  name                  = "${var.vm_secondary_name_prefix}${count.index}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  vm_size               = var.vm_secondary_vm_size
  network_interface_ids = ["${element(azurerm_network_interface.secondary.*.id, count.index)}"]
  count                 = var.vm_number_of_secondarys
  availability_set_id   = azurerm_availability_set.secondary.id
  depends_on            = ["azurerm_storage_account.secondary", "azurerm_network_interface.secondary", "azurerm_storage_container.secondary"]

  storage_image_reference {
    publisher = var.os_image_publisher
    offer     = var.os_image_offer
    sku       = var.os_version
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.vm_secondary_os_disk_name_prefix}${count.index}"
    vhd_uri       = "http://${element(azurerm_storage_account.secondary.*.name, count.index)}.blob.core.windows.net/${element(azurerm_storage_container.secondary.*.name, count.index)}/${var.vm_secondary_os_disk_name_prefix}.vhd"
    create_option = "FromImage"
    caching       = "ReadWrite"
  }

  os_profile {
    computer_name  = "${var.vm_secondary_name_prefix}${count.index}"
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
    type     = "ssh"
    host     = element(azurerm_public_ip.secondary.*.ip_address, count.index)
    user     = var.vm_admin_username
    password = var.vm_admin_password
  }

  provisioner "remote-exec" {
    inline = [
      "wget ${var.artifacts_location}${var.script_spark_provisioner_script_file_name}",
      "echo ${var.vm_admin_password} | sudo -S sh ./${var.script_spark_provisioner_script_file_name} -runas=secondary -primary=${var.nic_primary_node_ip}",
    ]
  }
  tags = {
    yor_trace = "b7d1b53f-1f89-4362-923d-3091546206e0"
  }
}

# ********************** CASSANDRA VIRTUAL MACHINE ********************** #
resource "azurerm_virtual_machine" "cassandra" {
  name                  = var.vm_cassandra_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  vm_size               = var.vm_cassandra_vm_size
  network_interface_ids = ["${azurerm_network_interface.cassandra.id}"]
  depends_on            = ["azurerm_storage_account.cassandra", "azurerm_network_interface.cassandra", "azurerm_storage_container.cassandra"]

  storage_image_reference {
    publisher = var.os_image_publisher
    offer     = var.os_image_offer
    sku       = var.os_version
    version   = "latest"
  }

  storage_os_disk {
    name          = var.vm_cassandra_os_disk_name
    vhd_uri       = "http://${azurerm_storage_account.cassandra.name}.blob.core.windows.net/${azurerm_storage_container.cassandra.name}/${var.vm_cassandra_os_disk_name}.vhd"
    create_option = "FromImage"
    caching       = "ReadWrite"
  }

  os_profile {
    computer_name  = var.vm_cassandra_name
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
    type     = "ssh"
    host     = azurerm_public_ip.cassandra.ip_address
    user     = var.vm_admin_username
    password = var.vm_admin_password
  }

  provisioner "remote-exec" {
    inline = [
      "wget ${var.artifacts_location}${var.script_cassandra_provisioner_script_file_name}",
      "echo ${var.vm_admin_password} | sudo -S sh ./${var.script_cassandra_provisioner_script_file_name}",
    ]
  }
  tags = {
    yor_trace = "2d415eb3-8a25-4dae-b99b-af3034848ac1"
  }
}
