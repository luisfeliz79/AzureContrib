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




locals  {

  rg_prefix                = "RouteServerLab"

  nva_name                 = "RSLABNVA"
  nva_internal_nic_ip      = "10.50.1.4"
  nva_external_nic_ip      = "10.50.2.4"
  nva2_name                = "RSLABNVA2"
  nva2_internal_nic_ip     = "10.50.1.5"
  nva2_external_nic_ip     = "10.50.2.5"   
  nva_admin_username       = "labadmin"
  vm_size                  = "Standard_B2ms"
  testvm_name              = "RSLABTestVM"
  onprem_name              = "OnPremRouterVM"
  onprem_external_nic_ip   = "10.20.0.4"
  onprem_network           = "10.20.0.0/24"
  
}

resource "random_string" "suffix" {
  length = 5
  upper = false
  special = false
}

resource "random_password" "sharedsecret" {
  length = 15
  upper = true
  special = true  
}



# Resource groups 
resource "azurerm_resource_group" "hub_rg" {
    name                        = "${local.rg_prefix}-Hub"
    location                    = var.location
}

resource "azurerm_resource_group" "spoke_rg" {
    name                        = "${local.rg_prefix}-Spoke"
    location                    = var.location
}

resource "azurerm_resource_group" "onprem_rg" {
    name                        = "${local.rg_prefix}-OnPremSimulated"
    location                    = var.location
}







# output "ROUTESERVER_PEER_IP" {
#   value = tolist(azurerm_route_server.rs1.virtual_router_ips)[0]
# }