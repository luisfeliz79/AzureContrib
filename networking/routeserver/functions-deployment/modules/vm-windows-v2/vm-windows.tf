resource "azurerm_public_ip" "pip"  {

    count               = var.enable_public_ip ? 1 : 0

    name                = "${var.vm_name}-pip"
    location            = var.vm_location
    resource_group_name = var.vm_rg_name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}

# Internal NIC
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

# Virtual Machine for NVA

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.vm_name}"
  location              = var.vm_location
  resource_group_name   = var.vm_rg_name
  network_interface_ids = [
        azurerm_network_interface.internal_nic.id        
  ]
  size               = var.vm_size

  admin_username     = var.vm_admin_username
  admin_password     = var.vm_admin_password

  #zones = ["1"]
  
  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
 
  os_disk {
    name              = "${var.vm_name}-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  timeouts {
      create = "60m"
      delete = "2h"
  }

  boot_diagnostics {
    storage_account_uri = null
  }


  lifecycle {
    ignore_changes = all
  }

}
 
resource "azurerm_dev_test_global_vm_shutdown_schedule" "sched" {
  virtual_machine_id           = azurerm_windows_virtual_machine.vm.id
  location                     = var.vm_location

  enabled                      = true

  daily_recurrence_time = "1900"
  timezone              = "Eastern Standard Time"
  
  notification_settings {
    enabled         = false
    time_in_minutes = "60"
    webhook_url     = "https://sample-webhook-url.example.com"
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "custom" {

    count = var.custom_script_settings != null ? 1 : 0

    name                 = "custom-script"
    virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    auto_upgrade_minor_version = true    
    
    settings = var.custom_script_settings
  
}


# resource "azurerm_virtual_machine_extension" "client1_build" {
#     name                    = "Client-build-CustomScript"
#     virtual_machine_id = azurerm_virtual_machine.spoke1vm.id
#     publisher            = "Microsoft.Compute"
#     type                 = "CustomScriptExtension"
#     type_handler_version = "1.10"
#     auto_upgrade_minor_version = true    
    
#   settings = <<SETTINGS
#     {
#         "fileUris": [
#            "https://luisnycartifacts.blob.core.windows.net/cseartifacts/WinRRASasNVA-BuildClients.ps1"

#            ],
#       "commandToExecute": "powershell.exe -Command \"./WinRRASasNVA-BuildClients.ps1\""


#     }
#   SETTINGS
  
# }


# resource "azurerm_virtual_machine_extension" "nvabuild" {
#     name                    = "${local.nva_name}-build"
#     virtual_machine_id = azurerm_virtual_machine.NVA.id
#     publisher            = "Microsoft.Compute"
#     type                 = "CustomScriptExtension"
#     type_handler_version = "1.10"
#     auto_upgrade_minor_version = true    
    
#   settings = <<SETTINGS
#     {
#         "fileUris": [
#            "https://raw.githubusercontent.com/luisfeliz79/AzureContrib/main/RouteServerLab/artifacts/RouteServerLabNVABuild.ps1"

#            ],
#       "commandToExecute": "powershell.exe -Command \"./RouteServerLabNVABuild.ps1 -LocalBGPIP '${local.nva_internal_nic_ip}' -RemoteVPNIP '${azurerm_public_ip.onprem_external_ip.ip_address}' -RemoteVPNBGPPeerIP '${local.onprem_external_nic_ip}' -RouteServerBGPPeerIP '${tolist(azurerm_route_server.rs1.virtual_router_ips)[0]}','${tolist(azurerm_route_server.rs1.virtual_router_ips)[1]}' -SharedSecret '${random_password.sharedsecret.result}' ; exit 0;\""


#     }
#   SETTINGS
  
# }



# resource "azurerm_virtual_machine_extension" "testvmwebserver1" {
#     name                    = "${local.testvm1_name}-build"
#     virtual_machine_id = azurerm_virtual_machine.TestClient1.id
#     publisher            = "Microsoft.Compute"
#     type                 = "CustomScriptExtension"
#     type_handler_version = "1.10"
#     auto_upgrade_minor_version = true
    
#   settings = <<SETTINGS
#     {
#         "fileUris": [
#            "https://raw.githubusercontent.com/luisfeliz79/AzureContrib/main/RouteServerLab/artifacts/RouteServerLabTestVMWebServer.ps1"

#            ],
#       "commandToExecute": "powershell.exe -Command \"./RouteServerLabTestVMWebServer.ps1 ; exit 0;\""


#     }
#   SETTINGS
  
# }


# output Test_WebServerVM1 {
#     value = "http://${azurerm_network_interface.testvm_internal_nic1.private_ip_address}"
# }

