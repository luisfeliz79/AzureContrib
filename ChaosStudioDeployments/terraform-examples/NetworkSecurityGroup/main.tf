terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.95.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Define some local variables
locals {
  prefix_name="chaos-nsg-test-tf"
  location="eastus"
}

# Create a resource group 
resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix_name}-rg"
  location = local.location
}



# Create a user assigned managed identity (UAMI)
resource "azurerm_user_assigned_identity" "uami" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${local.prefix_name}-testing-uami"
}

# Create an NSG
resource "azurerm_network_security_group" "test_nsg" { 
    name                        = "chaos-controlled-nsg"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location

}


# Deploy permissions for the Network Security Group for the UAMI
resource "azurerm_role_assignment" "nsg-rbac" {  
  scope                = azurerm_network_security_group.test_nsg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}

# Onboard the target Network Security Group  to Chaos Studio
# REF: https://learn.microsoft.com/en-us/rest/api/chaosstudio/targets/create-or-update?view=rest-chaosstudio-2024-01-01&tabs=HTTP
# REF: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/chaos_studio_target

resource "azurerm_chaos_studio_target" "nsg" {
  location           = azurerm_resource_group.rg.location
  target_resource_id = azurerm_network_security_group.test_nsg.id
  target_type        = "Microsoft-NetworkSecurityGroup"

  # Options as of 2/14/2024
  # Microsoft-Agent:[Microsoft.Compute/virtualMachines Microsoft.Compute/virtualMachineScaleSets]
  # Microsoft-AppService:[Microsoft.Web/sites] Microsoft-AutoscaleSettings:[Microsoft.Insights/autoscalesettings]     
  # Microsoft-AzureClusteredCacheForRedis:[Microsoft.Cache/Redis]
  # Microsoft-AzureKubernetesServiceChaosMesh:[Microsoft.ContainerService/managedClusters]
  # Microsoft-AzureLoadTest:[Microsoft.LoadTestService/loadtests]
  # Microsoft-CosmosDB:[Microsoft.DocumentDB/databaseAccounts] Microsoft-EventHub:[Microsoft.EventHub/namespaces]     
  # Microsoft-KeyVault:[Microsoft.KeyVault/vaults]
  # Microsoft-NetworkSecurityGroup:[Microsoft.Network/NetworkSecurityGroups]
  # Microsoft-ServiceBus:[Microsoft.ServiceBus/namespaces]
  # Microsoft-StorageAccount:[Microsoft.Storage/storageAccounts]
  # Microsoft-VirtualMachine:[Microsoft.Compute/virtualMachines]
  # Microsoft-VirtualMachineScaleSet:[Microsoft.Compute/virtualMachineScaleSets]
  # Microsoft-domainName:[Microsoft.ClassicCompute/domainNames]


}

# Add a capability for the NSG target
# REF: https://learn.microsoft.com/en-us/rest/api/chaosstudio/capabilities/create-or-update?view=rest-chaosstudio-2024-01-01&tabs=HTTP
# REF: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/chaos_studio_capability


resource "azurerm_chaos_studio_capability" "nsg-rule10" {
  chaos_studio_target_id = azurerm_chaos_studio_target.nsg.id
  capability_type        = "SecurityRule-1.0"
  # Options as of 2/14/2024
  #  SecurityRule-1.1    #This one has flush connections option
  #  SecurityRule-1.0

}

resource "azurerm_chaos_studio_capability" "nsg-rule11" {
  chaos_studio_target_id = azurerm_chaos_studio_target.nsg.id
  capability_type        = "SecurityRule-1.1"
  # Options as of 2/14/2024
  #  SecurityRule-1.1    #This one has flush connections option
  #  SecurityRule-1.0

}

# Create an experiment, leverage the User Assigned Managed Identity
# REF: https://learn.microsoft.com/en-us/rest/api/chaosstudio/experiments/create-or-update?view=rest-chaosstudio-2024-01-01&tabs=HTTP
# REF: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/chaos_studio_experiment

resource "azurerm_chaos_studio_experiment" "example" {
  location            = azurerm_resource_group.rg.location
  name                = "${local.prefix_name}-NSGRuleWithUAMI"
  resource_group_name = azurerm_resource_group.rg.name


  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uami.id]
  }

  selectors {
    name                    = "Selector1"    
    chaos_studio_target_ids = [azurerm_chaos_studio_target.nsg.id]
  }

  steps {
    name = "Step 1"
    branch {
      name = "Branch 1"
      actions {
        urn           = azurerm_chaos_studio_capability.nsg-rule11.urn
        selector_name = "Selector1"
        action_type   = "continuous"
        duration      = "PT10M"


        parameters    = {
          # Heads up, BRACKETS and escaping are needed.
          direction            = "Outbound"
          sourceAddresses      = "[\"0.0.0.0/0\"]"
          sourcePortRanges     = "[\"0-65535\"]"

          # Here you can do CIDR notation or Service Tag
          # List of Tags: https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview
          #destinationAddresses="[\"0.0.0.0/0\"]"
          destinationAddresses  ="[\"AzureActiveDirectory\"]"

          destinationPortRanges ="[\"0-65535\"]"
          protocol              = "Any"
          action                = "Deny"
          priority              = "4000"
          name                  = "DenyAzureActiveDirectory"
          flushConnection       = "true"  # true -> Reset active connections - Only Available with NSGRule1.1
        }
        

      }
    }
  }
}
