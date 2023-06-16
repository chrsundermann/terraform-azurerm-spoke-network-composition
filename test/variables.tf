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
    name        = string
    environment = string
    location    = string
  })
}

variable "hub_details" {
  description = "Infos about the hub vnet."
  type = object({
    hub_vnet_id = string
  })
}

variable "vnet_peering_to_hub" {
  description = "Peering options."
  type = object({
    peer_vnets_to_hub            = bool
    allow_virtual_network_access = bool
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    use_remote_gateways          = bool
  })
}