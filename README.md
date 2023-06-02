# Content

This repository provides a Terraform module which:
1) creates a complete Azure spoke network infrastructure including vnets, subnets, route tables and routes, network security groups and rules
2) takes yaml files as input

# Purpose

The purpose of this module is to make the network configuration as lean and simple as possible.

# Usage

Create env.secret file

```bash
#!/usr/bin/env bash
export ARM_CLIENT_ID="<client_id>"
export ARM_SUBSCRIPTION_ID="<subscription_id>"
export ARM_TENANT_ID="<tenant_id>"
export ARM_CLIENT_SECRET='<client_secret>'
export ARM_ACCESS_KEY='<access_key>'
export TF_VAR_subscription_id='<subscription_id_spoke>'
export TF_VAR_subscription_id_hub='<subscription_id_hub>'
```

Then execute commands in order:
```bash
source env.secret

terraform fmt
terraform init
terraform validate
terraform apply -var-file=settings/dev/terraform.tfvars
```

# Example

 - [yaml config files](examples/100/settings)
 - [test config files](test)

 Module configuration example:

 ```hcl
 locals {
  tags = {
    managedby   = "terraform"
    application = var.application_details.name
    environment = var.application_details.environment
  }
}

module "network-composition" {
  #source = "git::https://github.com/rigydi/terraform-azurerm-network-composition.git?ref=main"
  source = "../"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  tags = local.tags

  # network configuration
  network = yamldecode(file("${path.root}/settings/${var.application_details.environment}/network.yaml"))

  # route tables
  route_tables = yamldecode(file("${path.root}/settings/${var.application_details.environment}/route_tables.yaml"))

  # network security groups
  network_security_groups = yamldecode(file("${path.root}/settings/${var.application_details.environment}/network_security_groups.yaml"))

  # vnet peering to hub vnet
  hub_details         = var.hub_details
  vnet_peering_to_hub = var.vnet_peering_to_hub

  # details about the application/solution
  application_details = var.application_details
} 
 ```
</br>