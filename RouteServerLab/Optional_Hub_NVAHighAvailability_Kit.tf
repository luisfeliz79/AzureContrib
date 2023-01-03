# Windows Server as an NVA
# HA PAIR

resource "azurerm_public_ip" "nva_external_ip2" { 
    name                        = "nva2-external-ip"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.hub_rg.name
    allocation_method           = "Static"
    sku                         = "Standard" 
}




# Internal NIC
resource "azurerm_network_interface" "internal_nic2" { 
    name                              = "${local.nva_name}2-internal-nic"
    location                          = var.location
    resource_group_name               = azurerm_resource_group.hub_rg.name
    enable_ip_forwarding              = true 
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.hub_internal.id 
        private_ip_address_allocation = "Static"
        private_ip_address            = local.nva2_internal_nic_ip
    }
}

# External NIC
resource "azurerm_network_interface" "external_nic2" { 
    name                              = "${local.nva_name}2-external-nic"
    location                          = var.location
    resource_group_name               = azurerm_resource_group.hub_rg.name
    enable_ip_forwarding              = true 
    
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.hub_external.id  
        private_ip_address_allocation = "Static"
        private_ip_address            = local.nva2_external_nic_ip
        primary                       = true
        public_ip_address_id          =  azurerm_public_ip.nva_external_ip2.id
    }
}

# Virtual Machine for NVA

resource "azurerm_virtual_machine" "NVA2" {
  name                  = local.nva2_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.hub_rg.name
  network_interface_ids = [
        azurerm_network_interface.external_nic2.id,
        azurerm_network_interface.internal_nic2.id        
        
    ]
  vm_size               = local.vm_size
  
  primary_network_interface_id = azurerm_network_interface.external_nic2.id

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
 }
 
  storage_os_disk {
    name              = "${local.nva2_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
 
  os_profile {
    computer_name      = local.nva2_name
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
 
resource "azurerm_dev_test_global_vm_shutdown_schedule" "sched-nva2" {
  virtual_machine_id           = azurerm_virtual_machine.NVA2.id
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



resource "azurerm_virtual_machine_extension" "nvabuild2" {
    name                    = "${local.nva_name}-vmext"
    virtual_machine_id = azurerm_virtual_machine.NVA2.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.9"
    
  
  settings = <<SETTINGS
    {
        "fileUris": [
           "https://raw.githubusercontent.com/luisfeliz79/AzureContrib/main/RouteServerLab/artifacts/RouteServerLabNVABuild.ps1"

           ],
        "commandToExecute": "powershell.exe -Command \"./RouteServerLabNVABuild.ps1 -LocalBGPIP '${local.nva2_internal_nic_ip}' -RemoteVPNIP '${azurerm_public_ip.onprem_external_ip.ip_address}' -RemoteVPNBGPPeerIP '${local.onprem_external_nic_ip}' -RouteServerBGPPeerIP '${tolist(azurerm_route_server.rs1.virtual_router_ips)[0]}','${tolist(azurerm_route_server.rs1.virtual_router_ips)[1]}' -SharedSecret '${random_password.sharedsecret.result}' ; exit 0;\""

    }
  SETTINGS
  
}





resource "azurerm_virtual_machine_extension" "addVpnPeer2" {
    name                    = "${local.onprem_name}-add-peer"
    virtual_machine_id      = azurerm_virtual_machine.OnPremRouter.id
    publisher                  = "Microsoft.CPlat.Core"
    type                       = "RunCommandWindows"
    type_handler_version       = "1.1"
    auto_upgrade_minor_version = true



  settings = jsonencode({
   script = tolist([ "Invoke-WebRequest -Uri 'https://luisnycartifacts.blob.core.windows.net/cseartifacts/RouteServerLab2ndVPN.ps1' -OutFile RouteServerLab2ndVPN.ps1;./RouteServerLab2ndVPN.ps1 -RemoteVPNIP '${azurerm_public_ip.nva_external_ip2.ip_address}' -RemoteVPNBGPPeerIP '${local.nva2_internal_nic_ip}' -SharedSecret '${random_password.sharedsecret.result}' ; exit 0;"])
    
  })
  
  depends_on = [
    azurerm_virtual_machine_extension.OnPremRouterBuild
  ]
}


# resource "azurerm_virtual_machine_extension" "addVpnPeer2" {
#     name                    = "${local.onprem_name}-add-peer"
#     virtual_machine_id      = azurerm_virtual_machine.OnPremRouter.id
#     publisher            = "Microsoft.Compute"
#     type                 = "CustomScriptExtension"
#     type_handler_version = "1.10"
#     auto_upgrade_minor_version = true
    

#   settings = <<SETTINGS
#     {
#         "fileUris": [
#            "https://luisnycartifacts.blob.core.windows.net/cseartifacts/RouteServerLab2ndVPN.ps1"

#            ],
#         "commandToExecute": "powershell.exe -Command \"./RouteServerLab2ndVPN.ps1 -RemoteVPNIP '${azurerm_public_ip.nva_external_ip2.ip_address}' -RemoteVPNBGPPeerIP '${local.nva2_internal_nic_ip}' -SharedSecret '${random_password.sharedsecret.result}' ; exit 0;\""

#     }
#   SETTINGS
  
#   depends_on = [
#     azurerm_virtual_machine_extension.OnPremRouterBuild
#   ]
# }


# Add second Route Server peering
resource "azurerm_route_server_bgp_connection" "nvaconnection2" {
  name            = local.nva2_name
  route_server_id = azurerm_route_server.rs1.id
  peer_asn        = 65501
  peer_ip         = local.nva2_internal_nic_ip
}

output "CONNECT_NVA2" {
  value = "mstsc -v ${azurerm_public_ip.nva_external_ip2.ip_address}:22389"
}