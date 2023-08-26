# After creating DCEs and DCRs, you must associate them with VMs

# Use this Azure Policy to assign Data collection rules and endpoints to VMs at scale
# https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F2ea82cdd-f2e8-4500-af75-67a2e084ca74

# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "example1" {
  name                    = "example1-dcra"
  target_resource_id      = azurerm_linux_virtual_machine.vmregion0.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.rule1.id
  description             = "example"
}

# associate to a Data Collection Endpoint
resource "azurerm_monitor_data_collection_rule_association" "example2" {
  target_resource_id          = azurerm_linux_virtual_machine.vmregion0.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.region0dce.id
  description                 = "example"
}