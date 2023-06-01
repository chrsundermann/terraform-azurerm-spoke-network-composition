locals {
  tags = {
    managedby   = "terraform"
    environment = var.solution_details.environment
  }
}

module "network-composition" {
  source = "./modules/terraform-azurerm-network-composition"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  tags = local.tags

  # network configuration
  network = yamldecode(file("${path.root}/module_settings/network.yaml"))

  # route tables
  route_tables = yamldecode(file("${path.root}/module_settings/route_tables.yaml"))

  # network security groups
  network_security_groups = yamldecode(file("${path.root}/module_settings/network_security_groups.yaml"))

  # vnet peering to hub vnet
  hub_details         = var.hub_details
  vnet_peering_to_hub = var.vnet_peering_to_hub

  # details about the application/solution
  solution_details = var.solution_details
} 