# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "this" {
  name                = var.network.name
  resource_group_name = var.resource_group_name
  address_space       = var.network.address_space
  location            = var.location
  bgp_community       = var.network.bgp_community

  dynamic "ddos_protection_plan" {
    for_each = try(var.network.ddos_protection_plan, null) == null ? {} : var.network.ddos_protection_plan
    content {
      id     = ddos_protection_plan.value.id
      enable = ddos_protection_plan.value.enable
    }
  }

  dns_servers             = var.network.dns_servers
  edge_zone               = var.network.edge_zone
  flow_timeout_in_minutes = var.network.flow_timeout_in_minutes
  tags                    = try(var.tags, null)
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "this" {
  for_each = var.network.subnets

  name                 = "snet-${var.network.name}-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.subnet_delegation == null ? {} : each.value.subnet_delegation

    content {
      name = delegation.key

      dynamic "service_delegation" {
        for_each = delegation.value
        content {
          name    = service_delegation.value.name
          actions = service_delegation.value.actions
        }
      }
    }
  }

  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoints                             = each.value.service_endpoints
  #service_endpoint_policy_ids                   = lookup(var.network.subnet_service_endpoint_policy_ids, each.key, [])
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network
data "azurerm_virtual_network" "hub-network" {
  provider            = azurerm.hub-network
  count               = var.peering.peer-vnets-to-hub ? 1 : 0
  name                = var.hub_vnet.hub_vnet_name
  resource_group_name = var.hub_vnet.hub_vnet_resource_group_name
}

# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.peering.peer-vnets-to-hub ? 1 : 0

  name                      = "vpeer-${azurerm_virtual_network.this.name}-to-${data.azurerm_virtual_network.hub-network[0].name}"
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub-network[0].id
  resource_group_name       = var.resource_group_name

  allow_virtual_network_access = var.peering.allow_virtual_network_access
  allow_forwarded_traffic      = var.peering.allow_forwarded_traffic
  allow_gateway_transit        = var.peering.allow_gateway_transit
  use_remote_gateways          = var.peering.use_remote_gateways

  depends_on = [
    azurerm_virtual_network.this,
    azurerm_subnet.this,
    data.azurerm_virtual_network.hub-network
  ]
}


# Resource documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  provider = azurerm.hub-network
  for_each = var.network.link_these_private_dns_zones == null ? [] : var.network.link_these_private_dns_zones

  name                  = "dns-link-to-${trimprefix(trimsuffix(azurerm_virtual_network.this.id, "/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.network.name}"), "/subscriptions/")}"
  resource_group_name   = var.private_dns_zone_resource_group_name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.this.id
}