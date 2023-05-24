locals {
  tags = {
    managedby   = "terraform"
    environment = var.solution_environment
  }
}

module "network-composition" {
  source = "./modules/terraform-azurerm-network-composition"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  # network configuration
  network = yamldecode(file("${path.root}/network-settings/network.yaml"))

  # vnet peering to hub vnet
  hub_vnet_details = var.hub_vnet_details
  vnet_peering_to_hub  = var.vnet_peering_to_hub

  # private DNS zones location
  private_dns_zone_resource_group_name = var.private_dns_zone_resource_group_name

  # miscellaneous
  solution_name        = var.solution_name
  solution_environment = var.solution_environment
  solution_location    = var.solution_location
  tags                 = local.tags
} 