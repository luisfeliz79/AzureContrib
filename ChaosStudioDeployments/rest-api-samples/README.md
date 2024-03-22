# PowerShell
```powershell
az rest --method PUT -u "https://management.azure.com/subscriptions/xxxx-your-subscription-id-xxxx/resourceGroups/chaos/providers/Microsoft.Chaos/experiments/TestServiceBus?api-version=2024-01-01" --body "@./Experiment-Create-With-UserAssigned-ManagedIdentity-Sample.json"
```
# Bash
```bash
az rest --method PUT -u "https://management.azure.com/subscriptions/xxxx-your-subscription-id-xxxx/resourceGroups/chaos/providers/Microsoft.Chaos/experiments/TestServiceBus?api-version=2024-01-01" --body @"./Experiment-Create-With-UserAssigned-ManagedIdentity-Sample.json"
```