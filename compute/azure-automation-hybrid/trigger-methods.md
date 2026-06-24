# Azure Automation Runbook – Trigger Methods Comparison

A comprehensive comparison of the different ways to start (trigger) an Azure Automation Runbook.

| Method | Command / Endpoint | Supports Parameters | Authentication | Best For | Example |
|--------|-------------------|:-------------------:|----------------|----------|---------|
| **Webhook** | `POST https://<region>.azure-automation.net/webhooks?token=<token>` | ✅ Yes (JSON body) | Token embedded in URL (treat as secret) | External event-driven triggers, third-party integrations (GitHub, Azure DevOps, ServiceNow) | `curl -X POST '<webhook-url>' -H 'Content-Type: application/json' -d '{"Name":"Alice","Count":3}'` |
| **PowerShell (Az Module)** | `Start-AzAutomationRunbook` | ✅ Yes (`-Parameters` hashtable) | Azure AD (interactive or service principal) | Admin scripts, CI/CD pipelines, on-prem automation | `Start-AzAutomationRunbook -ResourceGroupName "MyRG" -AutomationAccountName "MyAA" -Name "MyRunbook" -Parameters @{VmName="TestVM"; Action="Start"}` |
| **Azure CLI** | `az automation runbook start` | ✅ Yes (`--parameters` JSON) | Azure AD (az login) | Shell scripts, DevOps pipelines, Linux environments | `az automation runbook start --automation-account-name MyAA --name MyRunbook --resource-group MyRG --parameters '{"VmName":"TestVM"}'` |
| **REST API (ARM)** | `POST https://management.azure.com/<resource-id>/jobs?api-version=2023-11-01` | ✅ Yes (JSON body `properties.parameters`) | Azure AD Bearer token | Custom applications, portals, advanced integrations | See [REST API example](#rest-api-example) below |


---

## Key Notes

- **Webhook URLs are secrets** – store them in Key Vault or secure variable groups. They cannot be retrieved after creation.
- **Hybrid Worker** – all methods above can target either an Azure sandbox or a Hybrid Runbook Worker by specifying `RunOn`.
- RBAC required `Automation Job Operator` and `Automation Runbook Operator` roles to start runbooks via PowerShell, CLI, or REST API.

---
## PowerShell Example
```powershell
Start-AzAutomationRunbook `
  -ResourceGroupName "MyRG" `
  -AutomationAccountName "MyAA" `
  -Name "MyRunbook" `
  -Parameters @{VmName="TestVM"; Action="Restart"} \
  -RunOn "MyHybridWorkerGroup"

``` 

## Azure CLI Example
```bash
az automation runbook start \

  --automation-account-name MyAA \
  --name MyRunbook \
  --resource-group MyRG \
  --subscription 12345678-abcd-efgh-ijkl-123456789abc \
  --parameters '{"VmName":"TestVM","Action":"Restart"}' \
  --run-on "MyHybridWorkerGroup" 
```


## REST API Example

```http
POST https://management.azure.com/subscriptions/12345678-abcd-efgh-ijkl-123456789abc/resourceGroups/MyRG/providers/Microsoft.Automation/automationAccounts/MyAA/jobs?api-version=2023-11-01
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "properties": {
    "runbook": {
      "name": "MyRunbook"
    },
    "parameters": {
      "VmName": "TestVM",
      "Action": "Restart"
    },
    "runOn": ""
  }
}
```

---

## References

| Resource | Link |
|----------|------|
| Webhooks | https://learn.microsoft.com/en-us/azure/automation/automation-webhooks |
| Start-AzAutomationRunbook | https://learn.microsoft.com/en-us/powershell/module/az.automation/start-azautomationrunbook |
| Azure CLI az automation | https://learn.microsoft.com/en-us/cli/azure/automation/runbook |
| REST API – Jobs | https://learn.microsoft.com/en-us/rest/api/automation/job/create |

