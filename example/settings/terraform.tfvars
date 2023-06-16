application_details = {
  name        = "myawesomeapp" # The name of the application for which the spoke network is deployed.
  environment = "dev"          # The environment of the application, e.g. dev, qas, prd.
  location    = "westeurope"   # The Azure region in which the application will be deployed.
}

hub_details = {
  hub_vnet_id                = "/subscriptions/ef031d65-6311-4db1-b3e0-5f0a84ad2239/resourceGroups/rg-core-network-prod-we/providers/Microsoft.Network/virtualNetworks/vnet-core-hub-prod-we" # The resource_id of the hub vnet.
}

vnet_peering_to_hub = {
  peer_vnets_to_hub            = true  # Peer the spoke vnets to hub?
  allow_virtual_network_access = true  # Controls if the VMs in the remote virtual network can access VMs in the local virtual network. Defaults to true.
  allow_forwarded_traffic      = false # Controls if forwarded traffic from VMs in the remote virtual network is allowed. Defaults to false.
  allow_gateway_transit        = false # Controls gatewayLinks can be used in the remote virtual network’s link to the local virtual network. Defaults to false.
  use_remote_gateways          = false # Controls if remote gateways can be used on the local virtual network. If the flag is set to true, and allow_gateway_transit on the remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Defaults to false.
}