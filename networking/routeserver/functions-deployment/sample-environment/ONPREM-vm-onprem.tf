
# deploy a windows vm using the windows module

module "onprem-nva-vm" {
  source = "../modules/vm-windows-v2"

  vm_name = local.vm_onprem_nva_name
  vm_size = local.vm_size
  vm_admin_username = local.vm_admin_username
  vm_admin_password = local.vm_admin_password
  vm_location = local.region
  vm_rg_name = azurerm_resource_group.onpremgw.name
  tags = local.tags
  vm_subnet_id = azurerm_subnet.onprem-nva.id
  enable_public_ip = true
}

output "onprem-nva-vm-ip" {
  value = module.onprem-nva-vm.VM_PUBLIC_IP
}






# module "onprem-nva-vm" {
#   source = "../modules/vm-linux"

#   vm_name = local.vm_onprem_nva_name
#   vm_size = local.vm_size
#   vm_admin_username = local.vm_admin_username
#   vm_admin_password = local.vm_admin_password
#   vm_location = local.region
#   vm_rg_name = azurerm_resource_group.onpremgw.name
#   tags = local.tags
#   vm_subnet_id = azurerm_subnet.onprem-nva.id
#   #enable_public_ip = true
#   #custom_script_settings = local.vm_settings
# }
