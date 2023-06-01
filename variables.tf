variable "subscription_id" {
  description = "The Azure subscription ID in which the resources will be deployed."
  type        = string
}

variable "subscription_id_hub" {
  description = "The Azure subscription ID in which hub network is located."
  type        = string
}

variable "solution_details" {
  description = "Basic infos about the application/solution for which the network components are deployed."
  type = object({
    name          = string # The name of the application/solution.
    environment                = string # "The environment of the solution, e.g. dev, qas, prd."
    location = string # "The Azure region in which the resources will be deployed."
  })
}

variable "hub_details" {
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