module "vpngateway" {

  count = local.include_vnetgw ? 1 : 0
    # This module creates a VPN Gateway in the Azure Hub VNET 
  source = "../modules/vpn-gateway"

  name                = "hub-vpngw"
  region              = local.region
  resource_group_name = azurerm_resource_group.azuregw.name

  gateway_subnet_id   = azurerm_subnet.azuregw-gw.id
  ONPREM_RTR_IP       = local.ONPREM_RTR_IP
  shared_key   = local.vm_admin_password
  VM_PUBLIC_IP = module.onprem-nva-vm.VM_PUBLIC_IP



  tags = local.tags
}

