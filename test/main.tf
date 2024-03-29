locals {
  tags = {
    managedby   = "terraform"
    application = var.application_details.name
    environment = var.application_details.environment
  }
}

module "network-composition" {
  #source = "git::https://github.com/rigydi/terraform-azurerm-network-composition.git?ref=main"
  source = "../"

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
  hub_details               = var.hub_details
  vnet_peering_spoke_to_hub = var.vnet_peering_spoke_to_hub
  vnet_peering_hub_to_spoke = var.vnet_peering_hub_to_spoke

  # details about the application/solution
  application_details = var.application_details

} 