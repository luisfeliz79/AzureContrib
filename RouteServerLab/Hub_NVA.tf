# Windows Server as an NVA
# Site to Site VPNs
# LAN Routing
# BGP Peering
# NAT?- TBD


resource "azurerm_public_ip" "nva_external_ip" { 
    name                        = "nva-external-ip"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.hub_rg.name
    allocation_method           = "Static"
    sku                         = "Standard" 
}




# Internal NIC
resource "azurerm_network_interface" "internal_nic" { 
    name                              = "${local.nva_name}-internal-nic"
    location                          = var.location
    resource_group_name               = azurerm_resource_group.hub_rg.name
    enable_ip_forwarding              = true 
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.hub_internal.id 
        private_ip_address_allocation = "Static"
        private_ip_address            = local.nva_internal_nic_ip
    }
}

# External NIC
resource "azurerm_network_interface" "external_nic" { 
    name                              = "${local.nva_name}-external-nic"
    location                          = var.location
    resource_group_name               = azurerm_resource_group.hub_rg.name
    enable_ip_forwarding              = true 
    
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.hub_external.id  
        private_ip_address_allocation = "Static"
        private_ip_address            = local.nva_external_nic_ip
        primary                       = true
        public_ip_address_id          =  azurerm_public_ip.nva_external_ip.id
    }
}

# Virtual Machine for NVA

resource "azurerm_virtual_machine" "NVA" {
  name                  = local.nva_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.hub_rg.name
  network_interface_ids = [
        azurerm_network_interface.external_nic.id,
        azurerm_network_interface.internal_nic.id        
        
    ]
  vm_size               = local.vm_size
  
  primary_network_interface_id = azurerm_network_interface.external_nic.id

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
 }
 
  storage_os_disk {
    name              = "${local.nva_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
 
  os_profile {
    computer_name      = local.nva_name
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
 
resource "azurerm_dev_test_global_vm_shutdown_schedule" "sched-nva" {
  virtual_machine_id           = azurerm_virtual_machine.NVA.id
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



resource "azurerm_virtual_machine_extension" "nvabuild" {
    name                    = "${local.nva_name}-build"
    virtual_machine_id = azurerm_virtual_machine.NVA.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    auto_upgrade_minor_version = true
    
  settings = <<SETTINGS
    {
        "fileUris": [
           "https://raw.githubusercontent.com/luisfeliz79/AzureContrib/main/RouteServerLab/artifacts/RouteServerLabNVABuild.ps1"

           ],
      "commandToExecute": "powershell.exe -Command \"./RouteServerLabNVABuild.ps1 -LocalBGPIP '${local.nva_internal_nic_ip}' -RemoteVPNIP '${azurerm_public_ip.onprem_external_ip.ip_address}' -RemoteVPNBGPPeerIP '${local.onprem_external_nic_ip}' -RouteServerBGPPeerIP '${tolist(azurerm_route_server.rs1.virtual_router_ips)[0]}','${tolist(azurerm_route_server.rs1.virtual_router_ips)[1]}' -SharedSecret '${random_password.sharedsecret.result}' ; exit 0;\""


    }
  SETTINGS
  
}

