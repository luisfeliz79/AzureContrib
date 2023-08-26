# Create the User Assigned Managed Identity
# Required for custom private dns zone setup
resource "azurerm_user_assigned_identity" "uaid1" {
  location            = local.location
  name                = "${local.cluster_name}-uaid1"
  resource_group_name = azurerm_resource_group.rg.name
}
