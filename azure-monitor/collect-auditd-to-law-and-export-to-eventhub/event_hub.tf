resource "azurerm_eventhub_namespace" "ehns" {
  name                = "${local.prefix}-eh-ns"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  sku                 = "Standard"
  capacity            = 1

  public_network_access_enabled = false
  local_authentication_enabled = false
  minimum_tls_version = "1.2"
  network_rulesets = [ 
    {

       # the value of public_network_access_enabled
       # at this level, should be the same as
       # at the namespace level
       public_network_access_enabled = false
      
       ip_rule = []
       virtual_network_rule = []
      
      # Only set default_action to Deny
      # when ip_rule or virtual_network_rule is not empty
      # Otherwise, use Allow
      default_action = "Allow"

      trusted_service_access_enabled = true
    }
  ]


}

resource "azurerm_eventhub" "auditd" {
  name                = "monitor-auditd"
  namespace_id     = azurerm_eventhub_namespace.ehns.id

  # Adjust based on expected load
  partition_count     = 1
  # Adjust as needed based on retention requirements
  message_retention   = 1
}

# This RBAC assignment is purely for For Lab testing
# It is not required for normal operation
resource "azurerm_role_assignment" "receiveperms1" {
  principal_id                     = data.azurerm_client_config.current.object_id
  role_definition_name             = "Azure Event Hubs Data Receiver"
  scope                            = azurerm_eventhub_namespace.ehns.id
  #skip_service_principal_aad_check = true
  principal_type = "User"
}