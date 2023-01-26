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

  location            = "eastus"
  rg_name             = "akstraining"
  cluster_name        = "aks${random_string.suffix.result}"
  address_space       = ["10.230.0.0/16"]
  subnet_akscni_space = ["10.230.0.0/24"]

  
}

# Resource groups 
resource "azurerm_resource_group" "rg" {
    name                        = local.rg_name
    location                    = local.location
}
