data "azurerm_monitor_diagnostic_categories" "cats" {
    resource_id = var.target_resource_id
}

resource "azurerm_monitor_diagnostic_setting" "diag" {
    name                       = "monitoring"
    target_resource_id         = var.target_resource_id
    log_analytics_workspace_id = var.log_analytics_workspace_id
    dynamic "enabled_log" {
        iterator = entry
        for_each = data.azurerm_monitor_diagnostic_categories.cats.log_category_types
        content {
            category = entry.value
            
            
        }

    }
    dynamic "enabled_metric" {
        iterator = entry
        for_each = data.azurerm_monitor_diagnostic_categories.cats.metrics
        content {
            category = entry.value
            #category_group = entry.value
        }
    }

}

# # Diagnostic settings for Activity Log
#  resource "azurerm_monitor_diagnostic_setting" "subscription-diag" {
#   name                       = "monitoring"
#   target_resource_id         = var.target_resource_id
#   log_analytics_workspace_id = var.log_analytics_workspace_id
# #   dynamic "enabled_log" {
# #     iterator = entry
# #     for_each = var.log_categories
# #     content {
# #       category = entry.value
# #     }
# #   }

#   enabled_log {
#     category = "AllLogs"
#   }

#   enabled_metric {
#     category = "AllMetrics"
#   }

# }
