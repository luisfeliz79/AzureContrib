
locals {
  subscription_id         = "<subscription_id>"
  resource_group_name     = "<resource-group-name>"
  location                = "eastus2"
  automation_account_name = "<automation-account-name>"
  arc_gateway_name        = "<arc-gateway-name>"
  storage_account_name    = "<storage-account-name>"
  key_vault_name          = "<key-vault-name>"
  law_name                = "<law-name>"
  egress_ip_address        = "<egress-ip-address>"
  
  tags                   = {
    environment = "poc"
    project     = "hybrid-automation"
  }

}