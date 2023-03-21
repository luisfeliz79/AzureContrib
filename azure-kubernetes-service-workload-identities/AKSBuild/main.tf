# Azure provider version 
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "= 3.32.0"
    }
    random = {
      source = "hashicorp/random"
      version = "= 3.4.3"
    }
    

  }
}

provider "azurerm" {
    features {} 
}


resource "random_string" "suffix" {
  length = 5
  upper = false
  special = false
}

locals  {

  location            = var.location
  rg_name             = var.resource_group
  cluster_name        = "aks${random_string.suffix.result}"
  address_space       = var.aks_cni_vnet_address_space
  subnet_akscni_space = var.aks_cni_subnet_address_space

}

# Resource groups 
resource "azurerm_resource_group" "rg" {
    name                        = local.rg_name
    location                    = local.location
}
