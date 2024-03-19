# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
  tags = {
    yor_trace = "22c7340b-77e7-4739-8192-2638bb8297c1"
  }
}

resource "azurerm_storage_account" "stor" {
  name                     = "${var.dns_name}stor"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  tags = {
    yor_trace = "9be2d965-4f3b-4763-a290-01cf6e32d6f4"
  }
}

resource "azurerm_availability_set" "avset" {
  name                         = "${var.dns_name}avset"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags = {
    yor_trace = "a4c690bf-4393-4425-9c25-b675cfeebb9f"
  }
}

resource "azurerm_public_ip" "lbpip" {
  name                = "${var.rg_prefix}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = var.lb_ip_dns_name
  tags = {
    yor_trace = "1abebdab-d9ed-4628-a6dd-f70dc88d2a08"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  address_space       = ["${var.address_space}"]
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    yor_trace = "c18f2949-fcf3-4349-8b0b-38446107522f"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.rg_prefix}subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.subnet_prefix}"]
}

resource "azurerm_lb" "lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${var.rg_prefix}lb"
  location            = var.location

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lbpip.id
  }
  tags = {
    yor_trace = "d9d17f13-aeda-4ced-87cc-8d6f787f9119"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "BackendPool1"
}

resource "azurerm_lb_nat_rule" "tcp" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "RDP-VM-${count.index}"
  protocol                       = "tcp"
  frontend_port                  = "5000${count.index + 1}"
  backend_port                   = 3389
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  count                          = 2
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.lb_probe.id
  depends_on                     = ["azurerm_lb_probe.lb_probe"]
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "tcpProbe"
  protocol            = "tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface" "nic" {
  name                = "nic${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  count               = 2

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    yor_trace = "1d816f64-cc58-45b6-9ecc-4f0f6179aa53"
  }
}


resource "azurerm_network_interface_nat_rule_association" "natrule" {
  network_interface_id  = "element(azurerm_network_interface.nic.*.id, count.index)"
  ip_configuration_name = "ipconfig${count.index}"
  nat_rule_id           = "element(azurerm_lb_nat_rule.tcp.*.id, count.index)"
  count                 = 2
}


resource "azurerm_virtual_machine" "vm" {
  name                  = "vm${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  availability_set_id   = azurerm_availability_set.avset.id
  vm_size               = var.vm_size
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  count                 = 2

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  storage_os_disk {
    name          = "osdisk${count.index}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = var.hostname
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {}
  tags = {
    yor_trace = "6c2fb703-bef6-4175-af4e-a94d2c018978"
  }
}
