# Terraform with Azure - Complete Guide

This repository contains comprehensive guides and examples for using Terraform to manage Azure infrastructure. The content is based on Pluralsight courses including "Hands-On with Terraform on Azure" and "Advanced Terraform with Azure".

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Getting Started](#getting-started)
3. [Basic Concepts](#basic-concepts)
4. [Azure Provider Setup](#azure-provider-setup)
5. [Core Resources](#core-resources)
6. [Advanced Topics](#advanced-topics)
7. [Best Practices](#best-practices)
8. [Common Patterns](#common-patterns)
9. [Troubleshooting](#troubleshooting)
10. [Additional Resources](#additional-resources)

## Prerequisites

Before you begin working with Terraform and Azure, ensure you have:

- **Azure CLI** installed and configured
- **Terraform** installed (version 1.0 or later recommended)
- **Azure subscription** with appropriate permissions
- **Text editor** or IDE (VS Code recommended)
- **Git** for version control

### Installation Commands

```bash
# Install Azure CLI (Windows)
winget install Microsoft.AzureCLI

# Install Terraform (Windows)
winget install Hashicorp.Terraform

# Verify installations
az --version
terraform --version
```

## Getting Started

### 1. Azure Authentication

First, authenticate with Azure:

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "your-subscription-id"

# Verify your account
az account show
```

### 2. Create Your First Terraform Configuration

Create a basic `main.tf` file:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-terraform-example"
  location = "East US"
}
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Plan your changes
terraform plan

# Apply the configuration
terraform apply
```

## Basic Concepts

### Terraform Core Components

- **Providers**: Plugins that interact with APIs (Azure, AWS, etc.)
- **Resources**: Infrastructure components (VMs, networks, storage)
- **Data Sources**: Read-only information from existing infrastructure
- **Variables**: Input parameters for configurations
- **Outputs**: Return values from configurations
- **Modules**: Reusable configuration components

### Terraform Workflow

1. **Write** - Author infrastructure as code
2. **Plan** - Preview changes before applying
3. **Apply** - Provision infrastructure
4. **Destroy** - Clean up resources when no longer needed

## Azure Provider Setup

### Basic Provider Configuration

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}
```

### Service Principal Authentication

For automated deployments, use service principal authentication:

```hcl
provider "azurerm" {
  features {}
  
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
```

## Core Resources

### Resource Groups

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment}-${var.application}"
  location = var.location

  tags = {
    Environment = var.environment
    Application = var.application
    Owner       = var.owner
  }
}
```

### Virtual Networks

```hcl
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}-${var.application}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}
```

### Storage Accounts

```hcl
resource "azurerm_storage_account" "main" {
  name                     = "st${var.environment}${var.application}001"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = azurerm_resource_group.main.tags
}
```

### Virtual Machines

```hcl
resource "azurerm_network_interface" "main" {
  name                = "nic-${var.environment}-${var.application}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-${var.environment}-${var.application}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  tags = azurerm_resource_group.main.tags
}
```

## Advanced Topics

### State Management

#### Remote State with Azure Storage

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate001"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

#### State Locking

Azure automatically provides state locking when using Azure Storage backend with blob storage.

### Modules

Create reusable modules for common patterns:

```hcl
# modules/web-app/main.tf
resource "azurerm_service_plan" "main" {
  name                = "sp-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }
}
```

### Data Sources

Use data sources to reference existing resources:

```hcl
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "existing" {
  name = "existing-rg"
}

data "azurerm_key_vault" "existing" {
  name                = "existing-kv"
  resource_group_name = data.azurerm_resource_group.existing.name
}
```

### Conditional Resources

```hcl
resource "azurerm_public_ip" "main" {
  count               = var.create_public_ip ? 1 : 0
  name                = "pip-${var.environment}-${var.application}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}
```

### For Each Loops

```hcl
variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    "web"    = { address_prefixes = ["10.0.1.0/24"] }
    "app"    = { address_prefixes = ["10.0.2.0/24"] }
    "data"   = { address_prefixes = ["10.0.3.0/24"] }
  }
}

resource "azurerm_subnet" "main" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
}
```

## Best Practices

### 1. Naming Conventions

Follow Azure naming conventions:

```hcl
locals {
  naming_convention = {
    resource_group  = "rg-${var.environment}-${var.application}-${var.location_short}"
    storage_account = "st${var.environment}${var.application}${random_integer.suffix.result}"
    virtual_machine = "vm-${var.environment}-${var.application}-${format("%03d", count.index + 1)}"
  }
}
```

### 2. Tagging Strategy

```hcl
locals {
  common_tags = {
    Environment   = var.environment
    Application   = var.application
    Owner         = var.owner
    CostCenter    = var.cost_center
    CreatedBy     = "Terraform"
    CreatedDate   = timestamp()
  }
}

resource "azurerm_resource_group" "main" {
  name     = local.naming_convention.resource_group
  location = var.location
  tags     = local.common_tags
}
```

### 3. Variable Validation

```hcl
variable "environment" {
  description = "The environment name"
  type        = string
  validation {
    condition     = can(regex("^(dev|test|prod)$", var.environment))
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  type        = string
  default     = "Standard_B1s"
  validation {
    condition = contains([
      "Standard_B1s",
      "Standard_B2s",
      "Standard_D2s_v3"
    ], var.vm_size)
    error_message = "VM size must be a supported SKU."
  }
}
```

### 4. Security Best Practices

```hcl
# Use managed identities
resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${var.environment}-${var.application}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Enable encryption
resource "azurerm_storage_account" "main" {
  name                     = local.naming_convention.storage_account
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"
  
  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }
}
```

### 5. Resource Dependencies

```hcl
# Explicit dependencies
resource "azurerm_virtual_machine_extension" "main" {
  name                 = "vm-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.main.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  depends_on = [
    azurerm_linux_virtual_machine.main,
    azurerm_storage_account.main
  ]
}
```

## Common Patterns

### 1. Three-Tier Architecture

```hcl
# Web tier
module "web_tier" {
  source = "./modules/web-tier"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  subnet_id          = azurerm_subnet.web.id
  environment        = var.environment
}

# Application tier
module "app_tier" {
  source = "./modules/app-tier"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  subnet_id          = azurerm_subnet.app.id
  environment        = var.environment
}

# Data tier
module "data_tier" {
  source = "./modules/data-tier"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  subnet_id          = azurerm_subnet.data.id
  environment        = var.environment
}
```

### 2. Hub and Spoke Network

```hcl
# Hub VNet
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Spoke VNets
resource "azurerm_virtual_network" "spoke" {
  for_each            = var.spoke_networks
  name                = "vnet-spoke-${each.key}-${var.environment}"
  address_space       = each.value.address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# VNet Peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                  = var.spoke_networks
  name                      = "peer-hub-to-${each.key}"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke[each.key].id
}
```

### 3. Auto Scaling

```hcl
resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "autoscale-${var.environment}-${var.application}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_virtual_machine_scale_set.main.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 2
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Provider Registration

```bash
# Register required resource providers
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
```

#### 2. State File Issues

```bash
# Refresh state
terraform refresh

# Import existing resources
terraform import azurerm_resource_group.main /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}

# Force unlock state
terraform force-unlock LOCK_ID
```

#### 3. Authentication Issues

```bash
# Clear Azure CLI cache
az account clear

# Re-authenticate
az login --tenant {tenant-id}
```

#### 4. Debugging

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive
```

### Error Patterns

- **Naming conflicts**: Use random suffixes for globally unique names
- **Quota limits**: Check Azure quotas and request increases if needed
- **Permission issues**: Ensure service principal has required roles
- **Region availability**: Verify resource availability in target regions

## Additional Resources

### Terraform Documentation
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

### Azure Documentation
- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)

### Learning Resources
- [Pluralsight: Hands-On with Terraform on Azure](notes/Hands-On%20with%20Terraform%20on%20Azure.pdf)
- [Pluralsight: Advanced Terraform with Azure](notes/Advanced%20Terraform%20with%20Azure.pdf)

### Tools and Extensions
- [Terraform VS Code Extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/)
