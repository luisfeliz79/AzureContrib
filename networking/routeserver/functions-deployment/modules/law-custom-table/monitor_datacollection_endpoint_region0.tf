
# Creates an Data collection endpoint (DCE)
# DCEs are region based, so create one for each region you want to monitor

# Use this Azure Policy to assign this Data collection endpoint to VMs at scale
# https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F2ea82cdd-f2e8-4500-af75-67a2e084ca74

resource "azurerm_monitor_data_collection_endpoint" "region0dce" {
  name                          = var.dce_name
  resource_group_name           = var.resource_group_name
  location                      = var.region
  public_network_access_enabled = true
  description                   = "Used by Virtual machines to connect to Azure Monitor"
}