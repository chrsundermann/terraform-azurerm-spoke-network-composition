locals {
  network = var.network.network
  network_settings = flatten([
    local.network == null ? [] : [
      for vnets, value in local.network : {
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
    ]
  ])

  route_tables = var.route_tables.route_tables
}

resource "azurerm_resource_group" "this" { 
  name     = "rg-network-${var.solution_name}-${var.solution_environment}"
  location = var.solution_location
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

resource "azurerm_route_table" "this" {
  for_each = try(local.route_tables, null) == null ? {} : local.route_tables

  name     = "rt-${each.key}-${var.solution_name}-${var.solution_environment}"
  resource_group_name = azurerm_resource_group.this.name
  location = azurerm_resource_group.this.location
  disable_bgp_route_propagation = each.value.disable_bgp_route_propagation

  depends_on = [ azurerm_resource_group.this ]
}

locals {
  route_table_associations = flatten([
    local.route_tables == null ? [] : [
      for route_table_in_file, route_table_config_in_file in local.route_tables : [
        route_table_config_in_file.subnet_associations == null ? [] : [
          for associated_subnet in route_table_config_in_file.subnet_associations : [
            for vnet, vnet_config in module.network : [
              for subnet_container, subnet_container_content in vnet_config : [
                for subnet, subnet_config in subnet_container_content : [
                  for route_table, route_table_config in azurerm_route_table.this : [
                    length(regexall(associated_subnet, subnet_config.name)) > 0 && length(regexall(route_table_in_file, route_table_config.name)) > 0 ? {
                      route_table_id = route_table_config.id
                      subnet_id = subnet_config.id
                      key = "${route_table}.${subnet}"
                    } : {}
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ])
  
  filtered_route_table_associations = [
    for association in local.route_table_associations : association if length(association) > 0
  ]

  route_table_associations_as_map = {for k, v in local.filtered_route_table_associations : v.key => v}

}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = local.route_table_associations_as_map

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id

  depends_on = [ module.network, azurerm_route_table.this ]
}

locals {
  routes = flatten([
    local.route_tables == null ? [] : [
      for route_table, route_table_config in local.route_tables : [
        route_table_config.routes == null ? [] : [
          for route, route_config in route_table_config.routes : {
            key = "${route}.${route_table}"
            name = "route-${route}-${var.solution_name}-${var.solution_environment}"
            route_table_name = "rt-${route_table}-${var.solution_name}-${var.solution_environment}"
            address_prefix = route_config.address_prefix
            next_hop_type = route_config.next_hop_type
            next_hop_in_ip_address = try(route_config.next_hop_in_ip_address, null)
          }
        ]
      ]
    ]
  ])

  routes_as_map = {for k, v in local.routes : v.key => v}
}

resource "azurerm_route" "this" {
  for_each = local.routes_as_map

  name = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  route_table_name = each.value.route_table_name
  address_prefix = each.value.address_prefix
  next_hop_type = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address

  depends_on = [ azurerm_route_table.this ]
}