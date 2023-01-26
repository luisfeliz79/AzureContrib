resource "azurerm_storage_account" "funcsa" {
  name                     = "rslabfuncsa"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.spoke_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_log_analytics_workspace" "ai_law" {
  name                = "rslablaw-${random_string.suffix.result}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.spoke_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "funcapp_insights" {
  name                = "reachonprem-ai"
  location            = var.location
  resource_group_name      = azurerm_resource_group.spoke_rg.name
  workspace_id        = azurerm_log_analytics_workspace.ai_law.id
  application_type    = "web"

  depends_on = [azurerm_log_analytics_workspace.ai_law]
}


resource "azurerm_service_plan" "funcplan" {
  name                     = "rslabfunc-plan"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.spoke_rg.name
  os_type                  = "Linux"
  sku_name                 = "B1"
}

resource "azurerm_linux_function_app" "funcapp" {
  name                     = "rslabfuncapp"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.spoke_rg.name

  storage_account_name       = azurerm_storage_account.funcsa.name
  storage_account_access_key = azurerm_storage_account.funcsa.primary_access_key
  service_plan_id            = azurerm_service_plan.funcplan.id

  site_config {
    vnet_route_all_enabled = true
    application_stack {
      powershell_core_version = "7.2"
    }
  
  }


  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.funcapp_insights.instrumentation_key}"
  }

  lifecycle {
    ignore_changes = all
  }





}

resource "azurerm_app_service_virtual_network_swift_connection" "funcappinjection" {
  app_service_id = azurerm_linux_function_app.funcapp.id
  subnet_id      = azurerm_subnet.spoke_Functions.id
}

resource "azurerm_function_app_function" "reach_onprem_function" {
  name            = "reachonprem"
  function_app_id = azurerm_linux_function_app.funcapp.id
  language        = "PowerShell"
  test_data = jsonencode({
    "name" = "Azure"
  })
  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "function"
        "direction" = "in"
        "methods" = [
          "get",
          "post",
        ]
        "name" = "Request"
        "type" = "httpTrigger"
      },
      {
        "direction" = "out"
        "name"      = "Response"
        "type"      = "http"
      },
    ]
  })

  file {
    name    = "run.ps1"
    content = file("artifacts/functionapp_run.ps1")
  }
}

