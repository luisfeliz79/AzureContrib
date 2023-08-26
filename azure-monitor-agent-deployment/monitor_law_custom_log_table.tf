
# This is an example of how to create a custom table in a Log Analytics Workspace
# This uses the AZAPI provider as of this writing, it is not possible using the AzureRM module

resource "azapi_resource" "lawtable" {
  
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  name      = "AuditD_CL"
  parent_id = azurerm_log_analytics_workspace.law.id
  

  body = jsonencode({
    properties = {
        schema = {
            name = "AuditD_CL",
            columns = [
                {
                    name = "TimeGenerated",
                    type = "DateTime"
                }, 
                {
                    name = "RawData",
                    type = "String"
                }
            ]
    }
    
    }
  })
}
