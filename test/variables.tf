variable "subscription_id" {
  description = "The Azure subscription ID in which the resources will be deployed."
  type        = string
  sensitive   = true
}

variable "subscription_id_hub" {
  description = "The Azure subscription ID in which hub network is located."
  type        = string
  sensitive   = true
}

variable "application_details" {
  description = "Basic infos about the application for which the network components are deployed."
  type = object({
    resource_group_name = optional(string)
    name        = string
    environment = string
    location    = string
  })
}

variable "hub_details" {
  description = "Infos about the hub."
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