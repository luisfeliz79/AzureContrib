# Experiment: Temporary Service bus topic disablement

This experiment will disable a Service Bus topic for a period of time and then re-enable it. This experiment is useful for testing the resiliency of your application to a Service Bus topic being disabled.

## Resources deployed by this experiment
- A resource group
- A Service Bus namespace
- A Service Bus topic
- Onboards the Service Bus namespace as a target in Azure Chaos studio
- Creates a capability in Azure Chaos studio to disable the Service Bus topic
- An experiment in Azure Chaos studio to disable the Service Bus topic, wait for a period of time, and then re-enable the Service Bus topic

## Using the Example
### Deploy the terraform plan
```bash
terraform init
terraform plan -out my.plan
terraform apply my.plan
```

### Start the experiment
```bash
experiment_id="/subscriptions/xxxxx-xxxxx-xxxxx/resourceGroups/chaos-rg/providers/Microsoft.Chaos/experiments/service-bus-experiment"

az rest --method post --uri "https://management.azure.com$experiment_id/start?api-version=2023-11-01"
```
### View the experiment's execution progress in Azure Chaos Studio

Visit the Azure Chaos Studio portal to view the experiment's execution progress.

[Chaos Studio Experiments](https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudioMenuBlade/~/chaosExperiment/defaultMenuItem/chaosExperiment)

### View the service bus topic status in the Azure Portal

[Service Bus](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.ServiceBus%2Fnamespaces)

### Optionally using Azure CLI to view the service bus topic status
```bash
# Define variables about the Service Bus
service_bus_namespace="<name of the service bus namespace>"
service_bus_resource_group="<the RG of the service bus namespace>"
service_bus_topic="<the service bus topic's name>"

# Use the watch utility and azure cli to monitor the status of the Service Bus topic, every 20 seconds
watch -d -n20 az servicebus topic show \
  --name $service_bus_topic \
  --namespace-name $service_bus_namespace \
  --resource-group $service_bus_resource_group \
  --query "{TopicName:name,TopicStatus:status}"
```

## Some useful Azure CLI commands to manage Service Bus topics
```bash
service_bus_namespace="<name of the service bus namespace>"
service_bus_resource_group="<the RG of the service bus namespace>"
service_bus_topic="<the service bus topic's name>"

# Get a list of topics and their states
az servicebus topic list \
  --namespace-name $service_bus_namespace \
  --resource-group $service_bus_resource_group \
  --query "[].{TopicName:name,TopicStatus:status}" \
   --output table
    
# Get a particular topic and its state
az servicebus topic show \
   --name $service_bus_topic \
   --namespace-name $service_bus_namespace \
   --resource-group $service_bus_resource_group \
   --query "{TopicName:name,TopicStatus:status}"
    
# Manually set the Topic status to Active
az servicebus topic update \
  --name $service_bus_topic \
  --namespace-name $service_bus_namespace \
  --resource-group $service_bus_resource_group \
  --status Active
    
# Manually set the Topic status to Disabled
az servicebus topic update \
  --name $service_bus_topic \
  --namespace-name $service_bus_namespace \
  --resource-group $service_bus_resource_group \
  --status Active 
```




