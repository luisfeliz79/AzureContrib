
# Internal NIC
resource "azurerm_network_interface" "testvm_internal_nic" { 
    name                              = "${local.testvm_name}-internal-nic"
    location                          = var.location
    resource_group_name               = azurerm_resource_group.spoke_rg.name
    enable_ip_forwarding              = true 
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.spoke_TestClients.id 
        private_ip_address_allocation = "Dynamic"
        
    }
}



# Virtual Machine - TestClient

resource "azurerm_virtual_machine" "TestClient" {
  name                  = local.testvm_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.spoke_rg.name
  network_interface_ids = [
        azurerm_network_interface.testvm_internal_nic.id,        
    ]
  vm_size               = local.vm_size
 
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
 }
 
  storage_os_disk {
    name              = "${local.testvm_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
 
  os_profile {
    computer_name      = local.testvm_name
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
 
resource "azurerm_dev_test_global_vm_shutdown_schedule" "sched2" {
  virtual_machine_id           = azurerm_virtual_machine.TestClient.id
  location                     = var.location

  enabled                      = true

  daily_recurrence_time = "0015"
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
    webhook_url     = "https://not-used.com"
  }
}


resource "azurerm_virtual_machine_extension" "testvmwebserver" {
    name                    = "${local.testvm_name}-build"
    virtual_machine_id = azurerm_virtual_machine.TestClient.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    auto_upgrade_minor_version = true
    
  settings = <<SETTINGS
    {
        "fileUris": [
           "https://raw.githubusercontent.com/luisfeliz79/AzureContrib/main/azure-route-server-testing-sandbox/artifacts/RouteServerLabTestVMWebServer.ps1"

           ],
      "commandToExecute": "powershell.exe -Command \"./RouteServerLabTestVMWebServer.ps1 ; exit 0;\""


    }
  SETTINGS
  
}


output Test_WebServerVM {
    value = "http://${azurerm_network_interface.testvm_internal_nic.private_ip_address}"
}