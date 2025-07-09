
module "azuregw-hubfw" {

    #count = local.include_firewall ? 1 : 0

    source = "../modules/vnet-peering-custom"
    left_vnet_object = azurerm_virtual_network.azurefwhub
    right_vnet_object = azurerm_virtual_network.azuregw
    left_subscription_id = local.subscription_id
    right_subscription_id = local.subscription_id

    # on left-to-right peering, use remote gateways
    use_remote_gateways = local.include_vnetgw ? true : false
    
    # on right-to-left peering, allow gateway transit
    allow_gateway_transit = local.include_vnetgw ? true : false
}


module "hubfw-spoke1" {
    #count = local.include_firewall ? 1 : 0

    source = "../modules/vnet-peering-custom"
    left_vnet_object = azurerm_virtual_network.azurespoke
    right_vnet_object = azurerm_virtual_network.azurefwhub
    left_subscription_id = local.subscription_id
    right_subscription_id = local.subscription_id
    
    # on left-to-right peering, use remote gateways
    #use_remote_gateways = true
    
    # on right-to-left peering, allow gateway transit
    #allow_gateway_transit = true 
    
}

# module "azuregw-hubfw" {
#     source = "../modules/vnet-peering-custom"
#     left_vnet_object = azurerm_virtual_network.azuregw
#     right_vnet_object = azurerm_virtual_network.azurefwhub
#     left_subscription_id = local.subscription_id
#     right_subscription_id = local.subscription_id    
# }
