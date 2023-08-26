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

# Primary Subscription
provider "azurerm" {
    features {} 
}

# Centralized DNS Subscription
provider "azurerm" {
    alias           = "centralized-dns-subscription"
    subscription_id = var.centralized-dns-subscription
    #client_id = ""
    #client_secret = "" 
    #tenant_id = ""   
    features {} 
}

# VWAN Subscription
provider "azurerm" {
    alias           = "vwan-subscription"
    subscription_id = var.vwan-subscription
    #client_id = ""
    #client_secret = "" 
    #tenant_id = ""   
    features {} 
}

