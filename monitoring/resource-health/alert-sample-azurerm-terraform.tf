terraform {
  required_providers {
    azurerm = {
      source  = "azurerm"
      version = ">=4.40.0"
    }
  }
}
provider "azurerm" {
  features {}
}
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "res-0" {
  auto_mitigation_enabled           = false
  description                       = "resource-health-alerts"
  display_name                      = "resource-health-alerts"
  enabled                           = true
  evaluation_frequency              = "PT5M"
  location                          = "eastus2"
  mute_actions_after_alert_duration = ""
  name                              = "resource-health-alerts"
  query_time_range_override         = ""
  resource_group_name               = "rg-foundational"
  scopes                            = ["/subscriptions/xxxxx/resourceGroups/rg-foundational/providers/Microsoft.OperationalInsights/workspaces/law-centralized"]
  severity                          = 3
  skip_query_validation             = false
  tags                              = {}
  target_resource_types             = ["Microsoft.OperationalInsights/workspaces"]
  window_duration                   = "PT5M"
  workspace_alerts_storage_enabled  = false
  action {
    action_groups     = ["/subscriptions/xxxxx/resourcegroups/alerts-to-teams/providers/microsoft.insights/actiongroups/send-to-teams"]
    custom_properties = {}
  }
  criteria {
    metric_measure_column   = ""
    operator                = "GreaterThan"
    query                   = "AzureActivity\n| where CategoryValue == \"ResourceHealth\"\n| where ResourceProviderValue == \"MICROSOFT.COMPUTE\"\n| extend Cause = Properties_d.cause\n| where Cause == \"PlatformInitiated\"\n| extend Details = tostring(Properties_d.details)\n| where Details != \"Unknown\" and isnotempty(Details)\n| extend Title = tostring(Properties_d.['title'])\n| extend Type = tostring(Properties_d.type)\n| extend Resource = tostring(Properties_d.resource)\n| extend resourceIdArray = split(_ResourceId, '/')\n| extend TopLevelResourceId = tostring(strcat_array(array_slice(resourceIdArray, 0, 8), '/'))\n| project\n    TimeGenerated,\n    Resource,\n    ActivityStatusValue,\n    Cause,\n    Type,\n    Title,\n    Details,\n    ResourceId = _ResourceId,\n    TopLevelResourceId,\n    SubscriptionId,\n    ResourceGroup,\n    OperationNameValue,\n    CorrelationId\n\n"
    resource_id_column      = "ResourceId"
    threshold               = 0
    time_aggregation_method = "Count"
    dimension {
      name     = "Resource"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "ActivityStatusValue"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "Type"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "Title"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "Details"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "TopLevelResourceId"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "SubscriptionId"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "ResourceGroup"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "OperationNameValue"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "CorrelationId"
      operator = "Include"
      values   = ["*"]
    }
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
}
