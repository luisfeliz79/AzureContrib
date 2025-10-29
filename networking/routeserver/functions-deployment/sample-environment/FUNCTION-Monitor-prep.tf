locals {

  custom_table_columns = [
    {
      name = "TimeGenerated"
      type = "DateTime"
    },
    {
      name = "RouteType"
      type = "String"
    },
    {
      name = "RouteServerName"
      type = "String"
    },
    {
      name = "ResourceGroupName"
      type = "String"
    },
    {
      name = "PeerName"
      type = "String"
    },
    {
      name = "PeerASN"
      type = "String"
    },
    {
      name = "RSInstance"
      type = "String"
    },
    {
      name = "Network"
      type = "String"
    },
    {
      name = "NextHop"
      type = "String"
    },
    {
      name = "Origin"
      type = "String"
    },
    {
      name = "SourcePeer"
      type = "String"
    },
    {
      name = "AsPath"
      type = "String"
    },
    {
      name = "Weight"
      type = "Int"
    },
    {
      name = "RunId"
      type = "String"
    }
  ]
}

module "customlog" {
  source = "../modules/law-custom-table"
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.law.id
  log_analytics_workspace_name  = azurerm_log_analytics_workspace.law.name
  dcr_name                      = "dcr-routes"
  resource_group_name           = azurerm_resource_group.azuregw.name
  dce_name                      = "dce-routes"
  custom_table_name             = "routes_CL"
  custom_table_columns          = local.custom_table_columns
  region                        = local.region
}

output "DCR_IMMUTABLE_ID" {
  value = module.customlog.DCR_IMMUTABLE_ID
}
output "DCE_INGEST_FQDN" {
  value = module.customlog.DCE_INGEST_FQDN
}