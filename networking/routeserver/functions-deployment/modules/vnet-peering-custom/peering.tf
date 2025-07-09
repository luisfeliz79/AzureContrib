
resource "azurerm_virtual_network_peering" "right_peering_left" {

    provider = azurerm.right

    name                        = "to-${var.left_vnet_object.name}"
    resource_group_name         = var.right_vnet_object.resource_group_name
    virtual_network_name        = var.right_vnet_object.name
    remote_virtual_network_id   = var.left_vnet_object.id
    allow_forwarded_traffic     = true
    allow_gateway_transit       = var.allow_gateway_transit
}

resource "azurerm_virtual_network_peering" "left_peering_right" {

    provider = azurerm

    name                        = "to-${var.right_vnet_object.name}"
    resource_group_name         = var.left_vnet_object.resource_group_name
    virtual_network_name        = var.left_vnet_object.name
    remote_virtual_network_id   = var.right_vnet_object.id
    allow_forwarded_traffic     = true
    allow_gateway_transit       = false   
    use_remote_gateways         = var.use_remote_gateways

    depends_on = [ azurerm_virtual_network_peering.right_peering_left ]
}


