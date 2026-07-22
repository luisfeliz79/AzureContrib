


# Subscription providers required for Azure Automation Hybrid Runbook Worker and Azure Arc-enabled servers

[!NOTE] Registering providers in a subscription requires the **Contributor** or higher role at the subscription level.

## Required Providers

When you create an Azure Automation Hybrid Runbook Worker or an Azure Arc-enabled server, you need to ensure that the required resource providers are registered in your Azure subscription. Below is a list of the necessary resource providers along with their purposes and documentation links.

| Resource Provider | Purpose |
|-------------------|---------|
| Microsoft.Automation | This provider is used for managing Azure Automation resources such as Automation Accounts, Runbooks, and Hybrid Runbook Workers. It allows you to automate tasks and orchestrate workflows across Azure and on-premises environments. [Documentation](https://docs.microsoft.com/en-us/azure/automation/automation-intro) |
| Microsoft.HybridCompute | This provider is used for managing Azure Arc-enabled servers. It allows you to onboard, manage, and monitor on-premises servers and virtual machines in Azure Arc. [Documentation](https://docs.microsoft.com/en-us/azure/azure-arc/servers/overview) |
| Microsoft.GuestConfiguration | This provider is used for managing Guest Configuration resources in Azure Policy. It allows you to define and enforce configuration policies on Azure Arc-enabled servers. [Documentation](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/guest-configuration) |
| Microsoft.HybridConnectivity | This provider is used for managing Azure Arc connectivity resources. It allows you to configure and manage the connectivity between Azure Arc-enabled servers and Azure. [Documentation](https://docs.microsoft.com/en-us/azure/azure-arc/servers/connectivity) |
| Microsoft.AzureArcData | This provider is used for managing Azure Arc-enabled data services. It allows you to manage Azure Arc-enabled SQL Server instances and PostgreSQL Hyperscale instances. [Documentation](https://docs.microsoft.com/en-us/azure/azure-arc/data/overview) |
| Microsoft.Storage | This provider is used for managing Azure Storage resources such as Storage Accounts and Blob Containers. It allows you to store and manage data in Azure Storage. [Documentation](https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction) |
| Microsoft.KeyVault | This provider is used for managing Azure Key Vault resources. It allows you to securely store and manage secrets, keys, and certificates in Azure Key Vault. [Documentation](https://docs.microsoft.com/en-us/azure/key-vault/general/overview) |
