output "arc_gateway_id" {
  description = "Terraform ID of the Azure Arc Gateway resource."
  value       = azapi_resource.arc_gateway.id
}

output "automation_account_hybrid_service_url" {
  description = "Fully qualified domain name of the Azure Automation account."
  value       = azurerm_automation_account.automation_account.hybrid_service_url  
}

output "arc_gateway_resource_id" {
  description = "Azure resource ID of the Azure Arc Gateway resource."
  value       = azapi_resource.arc_gateway.output.id
}

output "automation_account_id" {
  description = "Resource ID of the Azure Automation account."
  value       = azurerm_automation_account.automation_account.id
}