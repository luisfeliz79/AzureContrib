resource "azurerm_user_assigned_identity" "uami" {
  location            = azurerm_resource_group.rg.location
  name                = local.uami_name
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}
