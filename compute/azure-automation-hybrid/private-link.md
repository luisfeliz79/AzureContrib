# Private Link with Azure Automation

Azure Private Link allows you to access Azure Automation over a private endpoint that resides in your virtual network. This eliminates the need to expose your Automation account to the public internet, enhancing security by:

- Preventing data exfiltration over the public internet
- Allowing network-level access control
- Maintaining consistent network architecture for hybrid scenarios
- The public endpoint can be disabled after the private endpoint is configured, ensuring all traffic flows through the private link.

![Private Endpoints for Azure Automation](https://learn.microsoft.com/en-us/azure/automation/how-to/media/private-link-security/private-endpoints-automation.png)

## Prerequisites

Before implementing Private Link with Azure Automation, ensure you have:

1. **Azure Subscription**: Active subscription with Azure Automation account
2. **Virtual Network**: An existing VNet where the private endpoint will be created
3. **Subnet**: A dedicated subnet for the private endpoint (recommended /28 or smaller)
4. **DNS Infrastructure**: Either:
   - Azure Private DNS Zone - `privatelink.azure-automation.net` 
   - Azure DNS Private Resolver - For centralized DNS resolution across on-premises and Azure


## Network Requirements

### Azure Subnet Requirements
- **Size**: Minimum /28 subnet (or larger /27, /26 based on future needs)
- **Availability**: Subnet must be in the same region as Automation account


### Azure Hub Firewall Rules and OnPrem Firewalls
- Allow outbound connections to the private endpoint IP address
- Allow DNS queries to resolve Private Link DNS names


**On-Premises DNS Configuration:**
- Set up conditional forwarder on your on-premises DNS server
- Forward `azure-automation.net` queries to Azure DNS Private Resolver IP

## Private endpoints required

Two private endpoints are required for Azure Automation:
- Hybrid Runbook Worker Private Endpoint
- Azure Automation Webhooks Private Endpoint


## Related Resources


- [Azure Automation Private Endpoints](https://docs.microsoft.com/en-us/azure/automation/how-to-use-private-endpoints)
- [Azure Private DNS Zones](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview)
- [Azure DNS Private Resolver](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview)
- [Hybrid Runbook Worker Setup](https://docs.microsoft.com/en-us/azure/automation/automation-hybrid-runbook-worker)


