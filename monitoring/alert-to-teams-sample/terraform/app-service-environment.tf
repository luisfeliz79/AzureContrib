
resource "azurerm_app_service_environment_v3" "ase" {
  name                = "${local.logic_app_name}-ase"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.asev3.id

  #internal_load_balancing_mode = "Web, Publishing"
  #internal_load_balancing_mode = "None"

  zone_redundant = true

  cluster_setting {
    name  = "DisableTls1.0"
    value = "1"
  }

  cluster_setting {
    name  = "InternalEncryption"
    value = "true"
  }

  cluster_setting {
    name  = "FrontEndSSLCipherSuiteOrder"
    value = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
  }

  tags = local.tags

}

resource "azurerm_service_plan" "plan" {
  name                = "${local.logic_app_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  app_service_environment_id = azurerm_app_service_environment_v3.ase.id

  os_type  = "Windows"
  sku_name = "I1v2"


  
  #Uncomment the high availability settings below for
  #a production rollout
  
  #zone_balancing_enabled = true
  #worker_count = 2   # 2 or 3
  
}
