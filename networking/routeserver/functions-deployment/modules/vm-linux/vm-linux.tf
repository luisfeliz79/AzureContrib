# Creates a virtual machine and needed components
# and it runs the cloudinit script below
# It also installs the Azure Monitor Agent extension

locals {

cloudinit=<<CUSTOM_DATA
#!/bin/bash
sudo apt update -y
sudo apt install auditd -y
exit 0
CUSTOM_DATA

}

# resource "random_password" "password" {
#   length = 16
#   special = true
#   override_special = "_%@"
# }

resource "azurerm_public_ip" "pip"  {

    count               = var.enable_public_ip ? 1 : 0

    name                = "${var.vm_name}-pip"
    location            = var.vm_location
    resource_group_name = var.vm_rg_name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}



# NIC
resource "azurerm_network_interface" "internal_nic" { 
    name                              = "${var.vm_name}-internal-nic"
    location                          = var.vm_location
    resource_group_name               = var.vm_rg_name

    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = var.vm_subnet_id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.pip[0].id : null
    }

    tags = var.tags
}



# Virtual Machine

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.vm_name}"
  location              = var.vm_location
  resource_group_name   = var.vm_rg_name

  network_interface_ids = [
        azurerm_network_interface.internal_nic.id        
  ]
  
  size               = var.vm_size

  admin_username     = var.vm_admin_username
  admin_password     = var.vm_admin_password
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
 
  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  timeouts {
      create = "60m"
      delete = "2h"
  }

  identity {
    type = "SystemAssigned"
  }
  
  custom_data = base64encode(var.cloudinit)

  boot_diagnostics {
    storage_account_uri = null
  }

  lifecycle {
    ignore_changes = all
  }

}
 
resource "azurerm_dev_test_global_vm_shutdown_schedule" "schedregion0" {
  virtual_machine_id           = azurerm_linux_virtual_machine.vm.id
  location                     = var.vm_location

  enabled                      = true

  daily_recurrence_time = "1900"
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
    webhook_url     = "https://not-used.com"
  }
}

