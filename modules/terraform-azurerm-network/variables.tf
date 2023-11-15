variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "application_location" {
  description = "The Azure region in which the resources will be deployed."
  type        = string
}

variable "tags" {
  description = "A mapping of tags."
  type        = map(string)
}

variable "network" {
  description = "Network settings."
  type = object({
    name          = string
    address_space = set(string)
    bgp_community = optional(string)

    ddos_protection_plan = optional(map(object({
      id     = string
      enable = bool
    })))

    dns_servers             = optional(set(string))
    edge_zone               = optional(string)
    flow_timeout_in_minutes = optional(number)

    subnets = map(object({
      address_prefixes = set(string)

      subnet_delegation = optional(map(object({
        service_delegation = object({
          name    = string
          actions = set(string)
        })
      })))

      private_endpoint_network_policies_enabled     = optional(bool)
      private_link_service_network_policies_enabled = optional(bool)
      service_endpoints                             = optional(set(string))
    }))

    link_these_private_dns_zones = optional(set(string))
    dns_registration_enabled = optional(bool)
  })
}

variable "hub_details" {
  description = "Details about the hub."
  type = object({
    hub_vnet_name                = string
    hub_vnet_resource_group_name = string
    hub_dns_resource_group_name  = string
  })
}

variable "vnet_peering_spoke_to_hub" {
  type = object({
    peer_spoke_to_hub            = bool
    allow_virtual_network_access = bool
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    use_remote_gateways          = bool
  })
}

variable "vnet_peering_hub_to_spoke" {
  type = object({
    peer_hub_to_spoke            = bool
    allow_virtual_network_access = bool
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    use_remote_gateways          = bool
  })
}