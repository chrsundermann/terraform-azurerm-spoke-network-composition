#########################################
# This file is for testing purpose only. Remove this file in production scenarios!
#
# The resources created with this file are the hub resources (vnet and private DNS zone)
# to test the functionalities of terraform-azurerm-spoke-network-composition
#########################################

resource "azurerm_resource_group" "hub" {
  provider = azurerm.hub

  name     = element(split("/", "${var.hub_details.hub_vnet_id}"), 3) # vnet-hub-resourceGroup
  location = var.application_details.location
}

resource "azurerm_virtual_network" "hub" {
  provider = azurerm.hub

  name                = element(split("/", "${var.hub_details.hub_vnet_id}"), 7) # vnet-hub-name
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = ["10.0.0.0/24"]
}

resource "azurerm_private_dns_zone" "hub" {
  provider = azurerm.hub

  name                = "example.com"
  resource_group_name = var.hub_details.hub_vnet_resource_group_name

  depends_on = [azurerm_virtual_network.hub]
}