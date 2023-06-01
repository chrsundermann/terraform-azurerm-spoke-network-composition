variable "network" {
  description = "Network settings."
  type = object({
   network = map(object({
    #type = map(object({
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

variable "route_tables" {
  description = "Route table settings."
  type = object({
    route_tables = map(object({
      disable_bgp_route_propagation = string
      subnet_associations = optional(set(string))
      routes = map(object({
        address_prefix = string
        next_hop_type = string
        next_hop_in_ip_address = optional(string)
      }))
    }))
  })
}

variable "solution_location" {
  description = "The Azure region in which the resources will be deployed."
  type        = string
}

variable "solution_environment" {
  description = "The environment of the solution, e.g. dev, qas, prd."
  type        = string
}

variable "tags" {
  description = "A mapping of tags."
  type        = map(string)
}

variable "solution_name" {
  description = "The name of the solution."
  type        = string
}

variable "hub_vnet_details" {
  description = "Infos about the hub vnet."
  type = object({
    hub_vnet_name                = string # "The name of the hub vnet."
    hub_vnet_resource_group_name = string # "The name of the resource group in which the hub vnet is located."
  })
}

variable "vnet_peering_to_hub" {
  description = "Peering options."
  type = object({
    peer-vnets-to-hub            = bool # "Should the spoke vnets be peered to the already existing hub vnet? (true/false)"
    allow_virtual_network_access = bool # "Controls if the VMs in the remote virtual network can access VMs in the local virtual network. Defaults to true."
    allow_forwarded_traffic      = bool # "Controls if forwarded traffic from VMs in the remote virtual network is allowed. Defaults to false."
    allow_gateway_transit        = bool # "Controls gatewayLinks can be used in the remote virtual network’s link to the local virtual network. Defaults to false."
    use_remote_gateways          = bool # "Controls if remote gateways can be used on the local virtual network. If the flag is set to true, and allow_gateway_transit on the remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Defaults to false."
  })
}

variable "private_dns_zone_resource_group_name" {
  description = "The resource group in which the private DNS zones are located."
  type        = string
  default     = null
}