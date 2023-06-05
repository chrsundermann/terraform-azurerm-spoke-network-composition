locals {
  tags = {
    managedby   = "terraform"
    application = var.application_details.name
    environment = var.application_details.environment
  }
}

module "network-composition" {
  source = "git::https://github.com/rigydi/terraform-azurerm-network-composition.git?ref=main"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  tags = local.tags

  # network configuration
  network = yamldecode(file("${path.root}/settings/network.yaml"))

  # route tables
  route_tables = yamldecode(file("${path.root}/settings/route_tables.yaml"))

  # network security groups
  network_security_groups = yamldecode(file("${path.root}/settings/network_security_groups.yaml"))

  # vnet peering to hub vnet
  hub_details         = var.hub_details
  vnet_peering_to_hub = var.vnet_peering_to_hub

  # details about the application/solution
  application_details = var.application_details

  # Please delete the depends_on entry for production scenarios. This field is just for this test case to make sure a hub vnet is existing to peer the spoke vnets with.
  depends_on = [ azurerm_private_dns_zone.hub ]
} 