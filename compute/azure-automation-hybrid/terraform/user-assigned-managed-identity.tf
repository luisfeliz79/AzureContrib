# Managed Identity
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity
resource "azurerm_user_assigned_identity" "automation_identity" {
  name                = "automation-identity"
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = local.tags
}
