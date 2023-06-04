![Example](https://github.com/rigydi/terraform-azurerm-spoke-network-composition/actions/workflows/example.yaml/badge.svg?branch=main)

</br>

# Welcome to the Project!

Read [this](docs/CONTRIBUTING.md) for a quick introduction on how to **contribute**.

</br>

# Content

This repository provides a **Terraform module** which:
1) creates a complete **Azure spoke network infrastructure** including vnets, subnets, route tables and routes, network security groups and rules
2) takes yaml files as input

</br>

# Goal

The purpose of this module is to make a spoke network configuration as lean and simple as possible.

</br>

# Quick Start
## Step 1

Copy the [test](test) folder to your machine.

In case you are curious on how the terraform-azurerm-spoke-network module is referenced, have a look at the [main.tf](test/main.tf) file.

</br>

## Step 2
Copy the [settings](example/settings) folder to your test folder. Inside you will find yaml files containing configuration examples used as input to [main.tf](test/main.tf).

</br>

## Step 3

Create a file named **env.secret** with following content:

```bash
#!/usr/bin/env bash
export ARM_CLIENT_ID="<client_id>"
export ARM_SUBSCRIPTION_ID="<subscription_id>"
export ARM_TENANT_ID="<tenant_id>"
export ARM_CLIENT_SECRET='<client_secret>'
export TF_VAR_subscription_id='<subscription_id_spoke>'
export TF_VAR_subscription_id_hub='<subscription_id_hub>'
```

Optionally add **export ARM_ACCESS_KEY='<access_key>'** in case you want to configure a backend storage for storing the state file.

</br>

Now sequentially execute the following commands inside of your test folder:

```bash
source env.secret

terraform fmt
terraform init
terraform validate
terraform apply -var-file=settings/terraform.tfvars
```

</br>