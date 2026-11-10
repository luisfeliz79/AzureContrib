# Checklists

## Pre-staging check list
### Log Analytics Workspace
- Create Log Analytics Workspace 
- Enable the System assigned Identity
- Create the AuditD_CL custom table

### Data Collection artifacts
- Deploy the Data collection rule for AuditD logs. Note: It should be deployed in the same region as the LAW
- Deploy a regional Data Collection Endpoint for each region hosting VMs
- Deploy Azure Monitor Agent Extension on the VMs

### Event Hub
- Create the Event Hub Namespace
- Create an Event Hub AuditD within the namespace
- Configure a Role assignment for "Azure Event Hubs Data Owner" on the Event Hub Namespace, and for the Log Analytics Workspace's System assigned Identity
- Configure the Networking settings to allow "Trusted Microsoft Services"

## Configure Data Collection checklist
- Associate the Data Collection Endpoint with the VMs in the respective region
- Associate the Data Collection Rule on the VMs
- Use Azure Policy to enforce the association of the Data Collection Rule and Data Collection Endpoint on the VMs

## Enable Data Export to Event Hub checklist
- Configure the Log Analytics Workspace to export AuditD_CL logs to the Event Hub

## Configuring clients to consume Event Hub data checklist
- Configure a Role assignment for "Azure Event Hubs Data Receiver" on the Event Hub Namespace, and for the Client SPN
 
- Point the client to the Event Hub FQDN