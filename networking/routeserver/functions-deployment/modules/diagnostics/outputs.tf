output "list_of_cat_groups" {
    value = data.azurerm_monitor_diagnostic_categories.cats.log_category_groups
}

output "list_of_cat_types" {
    value = data.azurerm_monitor_diagnostic_categories.cats.log_category_types
}

output "list_of_metrics" {
    value = data.azurerm_monitor_diagnostic_categories.cats.metrics
}