terraform {
  required_version = "~> 1.4"
  required_providers {
    azurerm = "~> 3.51" # https://registry.terraform.io/providers/hashicorp/azurerm/latest
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "azurerm" {
  alias           = "hub"
  subscription_id = var.subscription_id_hub # vnet-hub-subscriptionId
  features {}
}