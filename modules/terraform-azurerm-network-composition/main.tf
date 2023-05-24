resource "azurerm_resource_group" "this" {
  name     = "rg-network-${var.solution_name}-${var.solution_environment}"
  location = var.solution_location
}

locals {
  settings = var.network
  network_settings = flatten([for vnets, value in local.settings.network : {
    # vnet settings
    name                    = vnets
    address_space           = value.address_space
    bgp_community           = value.bgp_community
    ddos_protection_plan    = value.ddos_protection_plan
    dns_servers             = value.dns_servers
    edge_zone               = value.edge_zone
    flow_timeout_in_minutes = value.flow_timeout_in_minutes

    # subnet settings
    subnets = value.subnets

    # private DNS zone links
    link_these_private_dns_zones = value.link_these_private_dns_zones
    }
  ])
}

module "network" {
  for_each = { for vnet, value in local.network_settings : "${value.name}" => value }
  source   = "./modules/terraform-azurerm-network"

  providers = {
    azurerm.hub = azurerm.hub
  }

  # miscellaneous
  resource_group_name = azurerm_resource_group.this.name
  solution_location            = azurerm_resource_group.this.location
  tags                = try(var.tags, null)

  network = {
    # vnet configuration
    name                    = "vnet-${each.key}-${var.solution_name}-${var.solution_environment}"
    address_space           = each.value.address_space
    bgp_community           = each.value.bgp_community
    ddos_protection_plan    = each.value.ddos_protection_plan
    dns_servers             = each.value.dns_servers
    edge_zone               = each.value.edge_zone
    flow_timeout_in_minutes = each.value.flow_timeout_in_minutes

    # subnet configuration
    subnets = each.value.subnets

    # private DNS zone links
    link_these_private_dns_zones = each.value.link_these_private_dns_zones
  }

  # peering
  hub_vnet_details = var.hub_vnet_details
  vnet_peering_to_hub  = var.vnet_peering_to_hub

  # private DNS zones location
  private_dns_zone_resource_group_name = var.private_dns_zone_resource_group_name
}