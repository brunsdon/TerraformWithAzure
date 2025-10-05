terraform {
  required_version = ">=1.13.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.47.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "IntManOpenSpaces-Stores-AustraliaSouthEast"
  location = "Australia Southeast"
}

resource "azurerm_storage_account" "storage" {
  name                     = "terratest01"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
}
