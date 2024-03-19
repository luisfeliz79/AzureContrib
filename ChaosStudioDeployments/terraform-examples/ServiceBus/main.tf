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
  prefix_name="chaos-test1"
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

# Create a service bus namespace
resource "azurerm_servicebus_namespace" "servicebusns" {
  name                = "${local.prefix_name}-sbus"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}

# Create a queue in the service bus namespace
resource "azurerm_servicebus_queue" "sbqueue" {
  name         = "testqueue"
  namespace_id = azurerm_servicebus_namespace.servicebusns.id
  enable_partitioning = true
}

# Create a topic in the service bus namespace
resource "azurerm_servicebus_topic" "sbtopic" {
  name         = "testtopic"
  namespace_id = azurerm_servicebus_namespace.servicebusns.id

  enable_partitioning = true
}

# Create a topic subscription in the service bus namespace
resource "azurerm_servicebus_subscription" "sbsubscription" {
  name               = "testsubscription"
  topic_id           = azurerm_servicebus_topic.sbtopic.id
  max_delivery_count = 1
}


# Deploy permissions for the service bus namespace for the UAMI
resource "azurerm_role_assignment" "servicebus-rbac" {  
  scope                = azurerm_servicebus_namespace.servicebusns.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}

# Onboard the target service bus namespace to Chaos Studio
resource "azurerm_chaos_studio_target" "servicebus" {
  location           = azurerm_resource_group.rg.location
  target_resource_id = azurerm_servicebus_namespace.servicebusns.id
  target_type        = "Microsoft-ServiceBus"

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

# Add a capabilities for the Service Bus target
resource "azurerm_chaos_studio_capability" "servicebus-queue-disable" {
  chaos_studio_target_id = azurerm_chaos_studio_target.servicebus.id
  capability_type        = "ChangeQueueState-1.0"
  # Options as of 2/14/2024
  #  ChangeQueueState-1.0
  #  ChangeSubscriptionState-1.0
  #  ChangeTopicState-1.0
}

# Add a capabilities for the Service Bus target
resource "azurerm_chaos_studio_capability" "servicebus-topic-disable" {
  chaos_studio_target_id = azurerm_chaos_studio_target.servicebus.id
  capability_type        = "ChangeTopicState-1.0"
  # Options as of 2/14/2024
  #  ChangeQueueState-1.0
  #  ChangeSubscriptionState-1.0
  #  ChangeTopicState-1.0
}

# Add a capabilities for the Service Bus target
resource "azurerm_chaos_studio_capability" "servicebus-subscription-disable" {
  chaos_studio_target_id = azurerm_chaos_studio_target.servicebus.id
  capability_type        = "ChangeSubscriptionState-1.0"
  # Options as of 2/14/2024
  #  ChangeQueueState-1.0
  #  ChangeSubscriptionState-1.0
  #  ChangeTopicState-1.0
}

# Create an experiment, leverage the User Assigned Managed Identity
# The experiment has sample steps to disable a queue, a topic, and subscription 
resource "azurerm_chaos_studio_experiment" "example" {
  location            = azurerm_resource_group.rg.location
  name                = "${local.prefix_name}-TestServiceBusWithUAMI"
  resource_group_name = azurerm_resource_group.rg.name


  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uami.id]
  }

  selectors {
    name                    = "Selector1"    
    chaos_studio_target_ids = [azurerm_chaos_studio_target.servicebus.id]
  }

  steps {
    name = "Step 1 - Disable Queue example"
    branch {
      name = "Branch 1"
      actions {
        urn           = azurerm_chaos_studio_capability.servicebus-queue-disable.urn
        selector_name = "Selector1"
        parameters = {
          # Heads up, BRACKETS and escaping are needed.
          # the queues attribute can be a comma separated list of queues   
          queues = "[\"testqueue\"]"
          desiredState = "Disabled"   #Active or Disabled
        }
        action_type = "discrete"

      }
    }
  }

  steps {
    name = "Step 2 - Disable Topic example"
    branch {
      name = "Branch 1"
      actions {
        urn           = azurerm_chaos_studio_capability.servicebus-topic-disable.urn
        selector_name = "Selector1"
        parameters = {
          # Heads up, BRACKETS and escaping are needed.
          # the queues attribute can be a comma separated list of topics   
          topics = "[\"testtopic\"]"
          desiredState = "Disabled"   #Active or Disabled
        }
        action_type = "discrete"

      }
    }
  }


  steps {
    name = "Step 3 - Disable Topic Subscription example"
    branch {
      name = "Branch 1"
      actions {
        urn           = azurerm_chaos_studio_capability.servicebus-subscription-disable.urn
        selector_name = "Selector1"
        parameters = {
          # Heads up, BRACKETS and escaping are needed.
          # the queues attribute can be a comma separated list of topics   
          topic = "testtopic"
          subscriptions = "[\"testsubscription\"]"
          desiredState = "Disabled"    #Active or Disabled
        }
        action_type = "discrete"

      }
    }
  }



}


