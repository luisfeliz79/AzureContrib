output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "VM_IP" {
  value = azurerm_network_interface.internal_nic.private_ip_address
}

output "VM_PUBLIC_IP" {
  value = var.enable_public_ip ? azurerm_public_ip.pip[0].ip_address : null
}


# output "VM_IP" {
#   value = azurerm_network_interface.internal_nic.private_ip_address
# }