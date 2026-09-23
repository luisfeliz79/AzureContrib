# Clients access to pulling notifications from Event Hub

Clients need to have appropriate permissions to pull notifications from the Event Hub. This involves configuring RBAC roles for the clients to have "Azure Event Hubs Data Receiver" access to the Event Hub.

## Configure RBAC access for clients
```bash
# This command configures an RBAC role assignment for a client to have "Azure Event Hubs Data Receiver" access to the chosen Event Hub (specified under --scope).
az role assignment create \
  --assignee "<client-object-id>" \
  --role "Azure Event Hubs Data Receiver" \
  --scope "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.EventHub/namespaces/myEventHubNamespace/eventhubs/myEventHub"
```

