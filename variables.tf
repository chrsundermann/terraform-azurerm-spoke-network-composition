##################################
# Vnets and Subnets
##################################

variable "network" {
  description = "Network settings."
  type = object({
    network = map(object({
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
    }))
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

variable "hub_details" {
  description = "Infos about the hub vnet."
  type = object({
    hub_vnet_name                = string
    hub_vnet_resource_group_name = string
  })
}

##################################
# Route Tables
##################################

variable "route_tables" {
  description = "Route table settings."
  type = object({
    route_tables = map(object({
      disable_bgp_route_propagation = string
      subnet_associations           = optional(set(string))
      routes = map(object({
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string)
      }))
    }))
  })
}

##################################
# Network Security Groups
##################################

variable "network_security_groups" {
  description = "Network Security Groups settings."
  type = object({
    network_security_groups = map(object({
      subnet_associations = optional(set(string))
      security_rules = map(object({
        protocol                                   = string
        source_port_range                          = optional(string)
        source_port_ranges                         = optional(set(string))
        destination_port_range                     = optional(string)
        destination_port_ranges                    = optional(set(string))
        source_address_prefix                      = optional(string)
        source_address_prefixes                    = optional(set(string))
        source_application_security_group_ids      = optional(set(string))
        destination_address_prefix                 = optional(string)
        destination_address_prefixes               = optional(set(string))
        destination_application_security_group_ids = optional(set(string))
        access                                     = string
        priority                                   = number
        direction                                  = string
      }))
    }))
  })
}

##################################
# Solution/Application specific details
##################################

variable "application_details" {
  description = "Basic infos about the application for which the network components are deployed."
  type = object({
    name        = string
    environment = string
    location    = string
  })
}

##################################
# Miscellaneous
##################################

variable "tags" {
  description = "A mapping of tags."
  type        = map(string)
}