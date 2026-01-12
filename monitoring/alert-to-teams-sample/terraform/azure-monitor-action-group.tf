resource "azurerm_monitor_action_group" "teams-alert-ag" {
  name                = "alert-to-teams-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "teamsalert"

   webhook_receiver {
    name                    = "call-logic-app-teams-alert"

    # If not using a secure webhook, get the SAS Url from the logic app and update here
    service_uri             = "https://${azurerm_logic_app_standard.logicapp.default_hostname}:443/api/alert-to-teams/triggers/When_an_HTTP_request_is_received/invoke?api-version=2022-05-01"
    use_common_alert_schema = true

    # Un comment to make this a secure webhook
    # for the service principal setup, see here
    # https://github.com/luisfeliz79/xxxxxx

    # aad_auth {
    #   object_id = azurerm_user_assigned_identity.uami.principal_id
    #   tenant_id = data.azurerm_client_config.current.tenant_id      
    # }

  }

 tags = local.tags
  
}