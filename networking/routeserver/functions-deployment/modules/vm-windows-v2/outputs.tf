
output "VM_IP" {
  value = azurerm_network_interface.internal_nic.private_ip_address
}

output "SystemMI_ID" {
  value = azurerm_windows_virtual_machine.vm.identity[0].principal_id
}

output "VM_OBJ" {
  value = azurerm_windows_virtual_machine.vm
}

output "VM_PUBLIC_IP" {
  value = var.enable_public_ip ? azurerm_public_ip.pip[0].ip_address : null
}