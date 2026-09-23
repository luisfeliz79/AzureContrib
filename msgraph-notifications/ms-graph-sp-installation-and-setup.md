
# Install the Microsoft Graph Change Tracking SP
This SP allows the "Graph Notification service" access to an Event Hub.

By default, this service principal is not installed on customer's tenant, and needs to be explicitly created using the command below.

## Install the SP
```bash
# This command installs the "Microsoft Graph Change Tracking" SP.  Because this is a tenant level change, an Entra ID "Cloud Application Administrator", "Application Administrator" or "Global Administrator" role is required.

az ad sp create --id 0bf30f3b-4a52-48df-9a82-234910c4a086
```

With least privilege scenario in mind, the access configured should be limited to sender access only. The access has to be configured as an RBAC assignment to the destination Event Hub.

## Configure RBAC access

```bash
# This commands configures an RBAC role assignment for the "Microsoft Graph Change Tracking" SP for your chosen eventhub (specified under --scope).

az role assignment create \
  --assignee "0bf30f3b-4a52-48df-9a82-234910c4a086" \
  --role "Azure Event Hubs Data Sender" \
  --scope "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.EventHub/namespaces/myEventHubNamespace/eventhubs/myEventHub"
```