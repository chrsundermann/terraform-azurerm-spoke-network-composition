##################################
# Vnets and Subnets
##################################

# remove first layer of data structure
locals {
  network = var.network.network
}

# data structure for vnets and subnets
locals {
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
        dns_registration_enabled     = value.dns_registration_enabled
      }
    ]
  ])
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "this" {
  name     = "rg-network-${var.application_details.name}-${var.application_details.environment}"
  location = var.application_details.location
  tags     = try(var.tags, null)

  # tags are typically provided by policies on Subscriptions or ResourceGroups and will be overwritten by
  # DeployIfNotExists policies this results in conflicts to each other
  lifecycle {
    ignore_changes = [tags]
  }
}

module "network" {
  for_each = { for vnet, vnet_config in local.network_settings : "${vnet_config.name}" => vnet_config }
  source   = "./modules/terraform-azurerm-network"

  providers = {
    azurerm.hub = azurerm.hub
  }

  # miscellaneous
  resource_group_name  = azurerm_resource_group.this.name
  application_location = azurerm_resource_group.this.location
  tags                 = try(var.tags, null)

  network = {
    # vnet configuration
    name                    = "vnet-${each.key}-${var.application_details.name}-${var.application_details.environment}"
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
    dns_registration_enabled     = each.value.dns_registration_enabled
  }

  # peering
  hub_details               = var.hub_details
  vnet_peering_hub_to_spoke = var.vnet_peering_hub_to_spoke
  vnet_peering_spoke_to_hub = var.vnet_peering_spoke_to_hub
}


##################################
# Route Tables
##################################

# remove first layer of data structure
locals {
  route_tables = var.route_tables.route_tables
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table
resource "azurerm_route_table" "this" {
  for_each = try(local.route_tables, null) == null ? {} : local.route_tables

  name                          = "rt-${each.key}-${var.application_details.name}-${var.application_details.environment}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  disable_bgp_route_propagation = each.value.disable_bgp_route_propagation
  tags                          = try(var.tags, null)

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    ignore_changes = [tags]
  }
}


# data structure for route table associations
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
                      subnet_id      = subnet_config.id
                      key            = "${route_table}.${subnet}"
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

  route_table_associations_as_map = {
    for k, v in local.filtered_route_table_associations : v.key => v
  }
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association
resource "azurerm_subnet_route_table_association" "this" {
  for_each = local.route_table_associations_as_map

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id

  depends_on = [module.network, azurerm_route_table.this]
}

# data structure for routes
locals {
  routes = flatten([
    local.route_tables == null ? [] : [
      for route_table, route_table_config in local.route_tables : [
        route_table_config.routes == null ? [] : [
          for route, route_config in route_table_config.routes : {
            key                    = "${route}.${route_table}"
            name                   = "route-${route}-${var.application_details.name}-${var.application_details.environment}"
            route_table_name       = "rt-${route_table}-${var.application_details.name}-${var.application_details.environment}"
            address_prefix         = route_config.address_prefix
            next_hop_type          = route_config.next_hop_type
            next_hop_in_ip_address = try(route_config.next_hop_in_ip_address, null)
          }
        ]
      ]
    ]
  ])

  routes_as_map = { for k, v in local.routes : v.key => v }
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route
resource "azurerm_route" "this" {
  for_each = local.routes_as_map

  name                   = each.value.name
  resource_group_name    = azurerm_resource_group.this.name
  route_table_name       = each.value.route_table_name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address

  depends_on = [azurerm_route_table.this]
}


##################################
# Network Security Groups
##################################

# remove first layer of data structure
locals {
  nsg = var.network_security_groups.network_security_groups
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "this" {
  for_each = try(local.nsg, null) == null ? {} : local.nsg

  name                = "nsg-${each.key}-${var.application_details.name}-${var.application_details.environment}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = try(var.tags, null)

  lifecycle {
    ignore_changes = [tags]
  }
}

# data structure for network security group association
locals {
  nsg_associations = flatten([
    local.nsg == null ? [] : [
      for nsg_in_file, nsg_config_in_file in local.nsg : [
        nsg_config_in_file.subnet_associations == null ? [] : [
          for associated_subnet in nsg_config_in_file.subnet_associations : [
            for vnet, vnet_config in module.network : [
              for subnet_container, subnet_container_content in vnet_config : [
                for subnet, subnet_config in subnet_container_content : [
                  for nsg, nsg_config in azurerm_network_security_group.this : [
                    length(regexall(associated_subnet, subnet_config.name)) > 0 && length(regexall(nsg_in_file, nsg_config.name)) > 0 ? {
                      nsg_id    = nsg_config.id
                      subnet_id = subnet_config.id
                      key       = "${nsg}.${subnet}"
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

  filtered_nsg_associations = [
    for association in local.nsg_associations : association if length(association) > 0
  ]

  nsg_associations_as_map = {
    for k, v in local.filtered_nsg_associations : v.key => v
  }
}

# Resource Documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.nsg_associations_as_map

  subnet_id                 = each.value.subnet_id
  network_security_group_id = each.value.nsg_id
}


# data structure for nsg rules
locals {
  rules = flatten([
    local.nsg == null ? [] : [
      for nsg, nsg_config in local.nsg : [
        nsg_config.security_rules == null ? [] : [
          for rule, rule_config in nsg_config.security_rules : {
            key                                        = "${rule}.${nsg}"
            name                                       = "nsgr-${rule}-${var.application_details.name}-${var.application_details.environment}"
            protocol                                   = rule_config.protocol
            source_port_range                          = try(rule_config.source_port_range, null)
            source_port_ranges                         = try(rule_config.source_port_ranges, null)
            destination_port_range                     = try(rule_config.destination_port_range, null)
            destination_port_ranges                    = try(rule_config.destination_port_ranges, null)
            source_address_prefix                      = try(rule_config.source_address_prefix, null)
            source_address_prefixes                    = try(rule_config.source_address_prefixes, null)
            destination_address_prefix                 = try(rule_config.destination_address_prefix, null)
            destination_address_prefixes               = try(rule_config.destination_address_prefixes, null)
            destination_application_security_group_ids = try(rule_config.destination_application_security_group_ids, null)
            source_application_security_group_ids      = try(rule_config.source_application_security_group_ids, null)
            access                                     = rule_config.access
            priority                                   = rule_config.priority
            direction                                  = rule_config.direction
            network_security_group_name                = "nsg-${nsg}-${var.application_details.name}-${var.application_details.environment}"
          }
        ]
      ]
    ]
  ])

  rules_as_map = { for k, v in local.rules : v.key => v }
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule
resource "azurerm_network_security_rule" "this" {
  for_each = local.rules_as_map

  name                                       = each.value.name
  network_security_group_name                = each.value.network_security_group_name
  resource_group_name                        = azurerm_resource_group.this.name
  protocol                                   = each.value.protocol
  source_port_range                          = try(each.value.source_port_range, null)
  source_port_ranges                         = try(each.value.source_port_ranges, null)
  destination_port_range                     = try(each.value.destination_port_range, null)
  destination_port_ranges                    = try(each.value.destination_port_ranges, null)
  source_address_prefix                      = try(each.value.source_address_prefix, null)
  source_address_prefixes                    = try(each.value.source_address_prefixes, null)
  destination_address_prefix                 = try(each.value.destination_address_prefix, null)
  destination_address_prefixes               = try(each.value.destination_address_prefixes, null)
  source_application_security_group_ids      = try(each.value.source_application_security_group_ids, null)
  destination_application_security_group_ids = try(each.value.destination_application_security_group_ids, null)
  access                                     = each.value.access
  priority                                   = each.value.priority
  direction                                  = each.value.direction

  depends_on = [azurerm_network_security_group.this]
}