# Create the User Assigned Managed Identity
# This is needed to allow the AMA agent to send data to the Event Hub
resource "azurerm_user_assigned_identity" "uaid1" {
  location            = azurerm_resource_group.rg0.location
  name                = "${local.prefix}-workid1"
  resource_group_name = azurerm_resource_group.rg0.name
}

