resource "azurerm_resource_group" "this" {
  name     = "rg-network-${var.solution_name}-${var.environment}"
  location = var.location
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
  source   = "./modules/vnet"

  providers = {
    azurerm.hub-network = azurerm.hub-network
  }

  network = {
    # vnet configuration
    name                    = "vnet-${each.key}-${var.solution_name}-${var.environment}"
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
  hub_vnet = var.hub_vnet
  peering  = var.peering

  # private DNS zones location
  private_dns_zone_resource_group_name = var.private_dns_zone_resource_group_name

  # miscellaneous
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = try(var.tags, null)
}