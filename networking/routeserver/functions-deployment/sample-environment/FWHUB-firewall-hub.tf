module "azure_firewall" {

  count = local.include_firewall ? 1 : 0

  source = "../modules/azure-firewall"

  fw_name          = local.fw_azurefwhub_name
  region           = local.region
  resource_group_name = azurerm_resource_group.azurefwhub.name
  subnet_fw_id     = azurerm_subnet.azurefwhub-fw.id
  subnet_mgmt_id   = azurerm_subnet.azurefwhub-fw-mgmt.id
  tags             = local.tags

}

