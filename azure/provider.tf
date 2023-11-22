terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  backend "azurerm" {
    resource_group_name  = "iac"
    storage_account_name = "terraformstatebvw"
    container_name       = "terraformstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  use_msi = true
}

resource "azurerm_resource_group" "rg" {
  name     = "iac-terraform"
  location = "eastus"
}

resource "azurerm_storage_account" "storage" {
  name                     = "brunowolffazure"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}