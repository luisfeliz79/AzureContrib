# Windows Server as an NVA
# Site to Site VPNs
# LAN Routing
# BGP Peering

resource "azurerm_public_ip" "onprem_external_ip" { 
    name                        = "onprem-external-ip"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.onprem_rg.name
    allocation_method           = "Static"
    sku                         = "Standard" 
}



# External NIC
resource "azurerm_network_interface" "onprem_external_nic" { 
    name                              = "${local.onprem_name}-external-nic"
    location                          = var.location
    resource_group_name               = azurerm_resource_group.onprem_rg.name
    enable_ip_forwarding              = true 
    
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.OnPrem_Router.id  
        private_ip_address_allocation = "Static"
        private_ip_address            = local.onprem_external_nic_ip
        primary                       = true
        public_ip_address_id          =  azurerm_public_ip.onprem_external_ip.id
    }
}

# Virtual Machine for NVA

resource "azurerm_virtual_machine" "OnPremRouter" {
  name                  = local.onprem_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.onprem_rg.name
  network_interface_ids = [
        azurerm_network_interface.onprem_external_nic.id

    ]
  vm_size               = local.vm_size
  
  primary_network_interface_id = azurerm_network_interface.onprem_external_nic.id

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
 }
 
  storage_os_disk {
    name              = "${local.onprem_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
 
  os_profile {
    computer_name      = local.onprem_name
    admin_username     = local.nva_admin_username
    admin_password     = var.nva_admin_password
  }
 
  os_profile_windows_config {
    provision_vm_agent = true
  }
 

  timeouts {
      create = "60m"
      delete = "2h"
  }
}
 
resource "azurerm_dev_test_global_vm_shutdown_schedule" "sched3" {
  virtual_machine_id           = azurerm_virtual_machine.OnPremRouter.id
  location                     = var.location

  enabled                      = true

  daily_recurrence_time = "0015"
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
    webhook_url     = "https://sample-webhook-url.example.com"
  }
}


resource "azurerm_virtual_machine_extension" "OnPremRouterBuild" {
    name                    = "${local.onprem_name}-build"
    virtual_machine_id = azurerm_virtual_machine.OnPremRouter.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    auto_upgrade_minor_version = true
    
    
    
  settings = <<SETTINGS
    {
        "fileUris": [
           "https://raw.githubusercontent.com/luisfeliz79/AzureContrib/main/azure-route-server-testing-sandbox/artifacts/RouteServerOnPremRouterBuild.ps1"

           ],
        "commandToExecute": "powershell.exe -Command \"./RouteServerOnPremRouterBuild.ps1 -LocalBGPIP '${local.onprem_external_nic_ip}' -RemoteVPNIP '${azurerm_public_ip.nva_external_ip.ip_address}' -RemoteVPNBGPPeerIP '${local.nva_internal_nic_ip}' -BgpCustomRoute '${local.onprem_network}'  -SharedSecret '${random_password.sharedsecret.result}' ; exit 0;\""

    }
  SETTINGS
  
}

output "CONNECT_ONPREM_ROUTER" {
  value = "mstsc -v ${azurerm_public_ip.onprem_external_ip.ip_address}:22389"
}