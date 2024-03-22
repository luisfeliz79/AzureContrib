# Using Azure Chaos Studio with Terraform

Terrform is a popular Infrastructure as Code (IaC) tool that allows you to define and provision infrastructure using a declarative configuration language. This repository contains examples of how to use Terraform to deploy resources that can be used with Azure Chaos Studio.

The Terraform AzureRM provider provides the following resources that can be used with Azure Chaos Studio:

|Resource|Description|
|---|---|
|[azurerm_chaos_studio_target](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/chaos_studio_target)|This resource is used to onboard and manage Azure Resources as a target into Chaos Studio.|
|[azurerm_chaos_studio_capability](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/chaos_studio_capability)|This resource is used to manage which faults are available for use against the target.|
|[azurerm_chaos_studio_experiment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/chaos_studio_experiment)|This resource is used to create and manage Chaos Studio experiments.|


## Examples
[Service Bus topic experiment](./ServiceBus-topic-disable-then-enable/README.MD)

[Network Security Group experiment](./NetworkSecurityGroup)


# Control Azure Chaos Studio experiments using Azure CLI

## Start an experiment
```bash
experiment_id="/subscriptions/xxxxx-xxxxx-xxxxx/resourceGroups/chaos-rg/providers/Microsoft.Chaos/experiments/service-bus-experiment"

az rest --method post --uri "https://management.azure.com$experiment_id/start?api-version=2023-11-01"
```

## Stop an experiment
This can be used when you wish to stop an experiment that is currently executing. Consider any steps that may have been already completed.
```bash
experiment_id="/subscriptions/xxxxx-xxxxx-xxxxx/resourceGroups/chaos-rg/providers/Microsoft.Chaos/experiments/service-bus-experiment"

az rest --method post --uri 'https://management.azure.com$experiment_id/start?api-version=2023-11-01'
```


# Comments about the Terraform syntax
```bash

# This is an example of onboarding a Service Bus namespace into Azure Chaos Studio using Terraform
resource "azurerm_chaos_studio_target" "servicebus" {
  location           = azurerm_resource_group.rg.location
  target_resource_id = azurerm_servicebus_namespace.servicebusns.id
  
  # The target_type is specific to each Azure resource type
  # To see a list of available target types
  # See here https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-fault-providers

  target_type        = "Microsoft-ServiceBus"

}

# Each target type has different capabilities (aka Faults)
# This example adds capabilities for the Service Bus target
# For a list of capabilities, see here:
# https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-fault-library

# These are options as of 2/14/2024
#  ChangeQueueState-1.0
#  ChangeSubscriptionState-1.0
#  ChangeTopicState-1.0
resource "azurerm_chaos_studio_capability" "servicebus-queue-disable" {
  chaos_studio_target_id = azurerm_chaos_studio_target.servicebus.id
  capability_type        = "ChangeQueueState-1.0"
}
resource "azurerm_chaos_studio_capability" "servicebus-topic-disable" {
  chaos_studio_target_id = azurerm_chaos_studio_target.servicebus.id
  capability_type        = "ChangeTopicState-1.0"
}
resource "azurerm_chaos_studio_capability" "servicebus-subscription-disable" {
  chaos_studio_target_id = azurerm_chaos_studio_target.servicebus.id
  capability_type        = "ChangeSubscriptionState-1.0"
}

# This is an example of for creating an experiment, leveraging the User Assigned Managed Identity
resource "azurerm_chaos_studio_experiment" "example" {
  location            = azurerm_resource_group.rg.location
  name                = "${local.prefix_name}-TestServiceBusWithUAMI"
  resource_group_name = azurerm_resource_group.rg.name

  # This configures the Managed Identity on the experiment
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uami.id]
  }

  # For each target thats part of this experiment
  # There should be a selector defined 
  selectors {
    name                    = "Selector1"    
    chaos_studio_target_ids = [azurerm_chaos_studio_target.servicebus.id]
  }

  # Each experiment can have multiple steps
  # Steps run sequentially
  # Each step can have multiple branches, and branches run in parallel
  # Each branch can have multiple actions, and each action runs in sequence
  

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
```
