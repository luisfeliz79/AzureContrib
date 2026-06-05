
# Networking Requirements for Azure Automation Hybrid Runbook Worker



| Endpoint | Description | TLS Inspection |
|----------|-------------|----------------|
| `<your Url prefix>`.gw.arc.azure.com | Specific Azure Arc Gateway endpoint. | Skip |
| management.azure.com | Azure's control plane API | OK |
| `<region>`.login.microsoft.com | Regional EntraID Identity Endpoint | OK |
| login.microsoftonline.com | Global EntraID Identity endpoint | OK |
| gbl.his.arc.azure.com | Azure Arc | OK |
| `<region>`.his.arc.azure.com | Azure Arc | OK |
| Packages.microsoft.com | MSFT Software repository | OK |
| Download.microsoft.com | MSFT Software repository | OK |
| security.ubuntu.com | Ubuntu Software repository | OK |
| archive.ubuntu.com | Ubuntu Software repository | OK |
| *.azure-automation.net | Azure Automation | OK |
| `<your automation account instance>`.jrds.eus2.azure-automation.net | Specific Azure Automation Hybrid worker service URL | Skip |

## Notes
- For `<your Url prefix>`.gw.arc.azure.com, this endpoint should not be TLS terminated.  It can be accessed via Proxy; however, TLS inspection should be disabled.  The reason why is because this uses a Microsoft specific protocol which breaks during TLS termination.   We detail the protocol here: https://learn.microsoft.com/en-us/azure/azure-arc/servers/arc-gateway?tabs=portal#azure-arc-gateway-forwarding-protocol

- The endpoints that use prefix of `<region>`, should be replaced with the region. For Example, for eastus2, the endpoints would be: 
    - eastus2.his.arc.azure.com
    - eastus2.login.microsoft.com

- For package management, this covers Windows based Hybrid workers
    - packages.microsoft.com
    - download.microsoft.com

 - But you should also consider operating specific distribution channels, such as apt repositories. For example, for ubuntu, I would also include:
    - security.ubuntu.com
    - archive.ubuntu.com

- To get the Specific Azure Arc Gateway endpoint and Specific Azure Automation Hybrid worker service URL, you can view it in the Azure portal, by visiting the resource and clicking on the JSON view link.

    - For Azure Arc Gateway endpoint, you can find it under the "properties" section with the name "gatewayEndpoint"
    - For Azure Automation Hybrid worker service URL, you can find it under the "properties" section with the name "automationHybridServiceUrl"

- You can also get these values via Azure CLI commands, replacing the variables with your values:
    - For Azure Arc Gateway endpoint: `az connectedmachine gateway show --resource-group <your resource group> --name <your gateway name> --query "gatewayPublicFqdn" -o tsv`
    - For Azure Automation Hybrid worker service URL: `az automation account show --resource-group <your resource group> --name <your automation account name> --query "hybridRunbookWorkerServiceUrl" -o tsv`  


