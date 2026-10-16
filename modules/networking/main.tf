resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-${var.resource_group_name}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-${var.vnet_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  name                 = "${var.name_prefix}-${var.subnet_name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

locals {
  inbound_rules = {
    ssh = {
      priority = 110
      port     = "22"
      source   = var.ssh_source_address_prefix
    }
    http = {
      priority = 120
      port     = "80"
      source   = "*"
    }
    https = {
      priority = 130
      port     = "443"
      source   = "*"
    }
  }
}

resource "azurerm_network_security_rule" "inbound" {
  for_each = local.inbound_rules

  name                        = "allow-${each.key}"
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.port
  source_address_prefix       = each.value.source
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

#inside network/varaibles.tf copy from line 104 till 147
variable "name_prefix" {
  type        = string
  description = "Prefix used for resource names."
}

variable "resource_group_name" {
  type        = string
  description = "Suffix for the resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "vnet_name" {
  type        = string
  description = "VNet name suffix."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address ranges."
}

variable "subnet_name" {
  type        = string
  description = "Subnet name suffix."
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Subnet address ranges."
}

variable "ssh_source_address_prefix" {
  type        = string
  description = "Source CIDR allowed to connect over SSH."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
}

inside networking/output.tf copy from line 150 till 173
output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Location of the resource group."
  value       = azurerm_resource_group.this.location
}

output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "subnet_id" {
  description = "ID of the subnet used by the VMs."
  value       = azurerm_subnet.this.id
}

output "network_security_group_id" {
  description = "ID of the network security group."
  value       = azurerm_network_security_group.this.id
}
