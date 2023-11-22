// AZURE TERRAFORM PROVIDER
provider "azurerm" {
  features {}
}

# Path: main.tf
# create a blob storage account

resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform"
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