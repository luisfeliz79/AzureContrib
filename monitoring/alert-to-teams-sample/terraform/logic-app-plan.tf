# resource "azurerm_service_plan" "plan" {
#   name                = "${local.logic_app_name}-plan"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   os_type  = "Windows"
#   sku_name = "WS1"
  
#   #Uncomment the high availability settings below for
#   #a production rollout
  
#   #zone_balancing_enabled = true
#   #worker_count = 2   # 2 or 3
  
# }
