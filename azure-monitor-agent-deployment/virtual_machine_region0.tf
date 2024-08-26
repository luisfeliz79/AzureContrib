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

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "azurerm_public_ip" "pip-region0" { 
    name                        = "pip-region0"
    location                    = local.region0
    resource_group_name         = azurerm_resource_group.rg0.name
    allocation_method           = "Static"
    sku                         = "Standard" 
}

resource "azurerm_virtual_network" "vnet-region0" {
    name                        = "vnet-${local.region0}"
    location                    = local.region0
    resource_group_name         = azurerm_resource_group.rg0.name
    address_space               = ["10.128.0.0/24"]
}

resource "azurerm_subnet" "subnet-region0" {
  name                      = "default"
  resource_group_name       = azurerm_resource_group.rg0.name
  virtual_network_name      = azurerm_virtual_network.vnet-region0.name
  address_prefixes          = ["10.128.0.0/25"]
}


# NIC
resource "azurerm_network_interface" "nic-vm-region0" { 
    name                              = "nic-vm${local.region0}"
    location                          = local.region0
    resource_group_name               = azurerm_resource_group.rg0.name
    
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.subnet-region0.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.pip-region0.id
    }
}



# Virtual Machine

resource "azurerm_linux_virtual_machine" "vmregion0" {
  name                  = "vm${local.region0}"
  location              = local.region0
  resource_group_name   = azurerm_resource_group.rg0.name
  network_interface_ids = [
        azurerm_network_interface.nic-vm-region0.id,        
    ]
  size               = local.vm_size
  admin_username     = local.admin_username
  admin_password     = random_password.password.result
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  timeouts {
      create = "60m"
      delete = "2h"
  }

  identity {
    type="UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uaid1.id]
  }

  
  custom_data = base64encode(local.cloudinit)


}
 
resource "azurerm_dev_test_global_vm_shutdown_schedule" "schedregion0" {
  virtual_machine_id           = azurerm_linux_virtual_machine.vmregion0.id
  location                     = local.region0

  enabled                      = true

  daily_recurrence_time = "0015"
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
    webhook_url     = "https://not-used.com"
  }
}

resource "azurerm_virtual_machine_extension" "azmonregion0" {
        
    name                       = "AzureMonitorLinuxAgent"
    publisher                  = "Microsoft.Azure.Monitor"
    type                       = "AzureMonitorLinuxAgent"
    type_handler_version       = 1.22
    auto_upgrade_minor_version = "true"
    
    virtual_machine_id   = azurerm_linux_virtual_machine.vmregion0.id
}


# resource "azurerm_network_security_group" "remotesshnsg-region0" { 
#     name                          = "remote-ssh-nsg-${local.region0}"
#     location                      = local.region0
#     resource_group_name           = azurerm_resource_group.rg0.name

#     security_rule {      
#       name                        = "AllowSSH"
#       priority                    = 100
#       direction                   = "Inbound"
#       access                      = "Allow"
#       protocol                    = "Tcp"
#       source_port_range           = "*"
#       destination_port_range      = "22"
#       source_address_prefix       = "1.2.3.4/32"
#       destination_address_prefix  = "*"
#     }

# }

# # Associate the NSG
# resource "azurerm_subnet_network_security_group_association" "nsg_assoc-region0" {
#   subnet_id                 = azurerm_subnet.subnet-region0.id
#   network_security_group_id = azurerm_network_security_group.remotesshnsg-region0.id
# }

output PublicIP {
  value = azurerm_linux_virtual_machine.vmregion0.public_ip_address
}
output user {
  value = local.admin_username
}

output password_help {
  value = "Azure Portal > Virtual Machines > pick your machine > Reset Password"
}
