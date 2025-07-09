output "DCR_IMMUTABLE_ID" {
  value = azurerm_monitor_data_collection_rule.rule1.immutable_id
}

output "DCR_RESOURCE_ID" {
  value = azurerm_monitor_data_collection_rule.rule1.id
}

output "DCE_INGEST_FQDN" {
  value = azurerm_monitor_data_collection_endpoint.region0dce.logs_ingestion_endpoint
}

