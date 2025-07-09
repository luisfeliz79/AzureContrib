
# This is an example of how to create a custom table in a Log Analytics Workspace
# This uses the AZAPI provider as of this writing, it is not possible using the AzureRM module


resource "azapi_resource" "lawtable" {
  
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"

  # Must have _CL at the end of the table name
  name      = var.custom_table_name
  parent_id = var.log_analytics_workspace_id
  

  body = {
    properties = {
        schema = {
            name = "${var.custom_table_name}",
            columns = var.custom_table_columns
    }
    
    }
  }
}
