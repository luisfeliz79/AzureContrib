terraform {
  required_providers {

    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.32.0"
    }

    azapi = {
      source = "Azure/azapi"
      version = "1.13.1"
    }

    
  }
}



provider "azurerm" {
    features {}
}

provider "azapi" {
  
}


# Resource groups 
resource "azurerm_resource_group" "rg" {
    name                        = "specialized-image-test"
    location                    = "eastus2"

}

# VNET
resource "azurerm_virtual_network" "vnet" {
    name                        = "test-vnet"
    location                    = azurerm_resource_group.rg.location 
    resource_group_name         = azurerm_resource_group.rg.name
    address_space               = ["10.0.0.0/16"]
}

# The default Subnet
resource "azurerm_subnet" "default_subnet" {
  name                      = "Default"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = ["10.0.0.0/24"]
}

# Internal NIC
resource "azurerm_network_interface" "internal_nic" { 
    name                              = "vmspecialized-internal-nic"
    location                          = azurerm_resource_group.rg.location
    resource_group_name               = azurerm_resource_group.rg.name
    enable_ip_forwarding              = false 
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.default_subnet.id
        private_ip_address_allocation = "Dynamic"
    }

}

# https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?pivots=deployment-language-terraform#terraform-azapi-provider-resource-definition
resource "azapi_resource" "vmspecialized" {
  type = "Microsoft.Compute/virtualMachines@2023-09-01"
  name = "vmthousandeyes"
  location = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  tags = {
    tagName1 = "tagValue1"
    tagName2 = "tagValue2"
  }

  body = jsonencode({
    properties = {

      hardwareProfile = {
        vmSize = "Standard_B2s_v2"
      }

      networkProfile = {
        networkInterfaces = [
          {
            id = azurerm_network_interface.internal_nic.id
          }
        ]
      }

      storageProfile = {

        
        imageReference = {
          id = "/subscriptions/xxxxx/resourceGroups/sig/providers/Microsoft.Compute/galleries/MySharedImageGallery/images/UbuntuWithTools"
        }
        osDisk = {
          createOption = "fromImage"
          managedDisk = {
            storageAccountType = "PREMIUM_LRS"
          }
         
        }
      }
      additionalCapabilities = {
        "hibernationEnabled" = false 
      }
      diagnosticsProfile = {
        "bootDiagnostics" = {
          "enabled" = true
        }
      }

    }

  })
}