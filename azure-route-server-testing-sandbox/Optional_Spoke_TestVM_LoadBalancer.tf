resource "azurerm_lb" "TestLB" {
  name                   = "TestClientLoadBalancer"
    location             = var.location
    resource_group_name  = azurerm_resource_group.spoke_rg.name

  frontend_ip_configuration {
    subnet_id = azurerm_subnet.spoke_TestClients.id 
    private_ip_address_allocation = "Dynamic"    
    name                          = "PrivateIP"
  }
  sku = "Standard"

}

resource "azurerm_lb_backend_address_pool" "testvmbepool" {
  loadbalancer_id = azurerm_lb.TestLB.id
  name            = "TestVMPool"
}

resource "azurerm_lb_backend_address_pool_address" "testvmbepooladdress" {
  name                    = "testvm"
  backend_address_pool_id = azurerm_lb_backend_address_pool.testvmbepool.id
  virtual_network_id      = azurerm_virtual_network.spoke_vnet.id
  ip_address              = azurerm_network_interface.testvm_internal_nic.private_ip_address
}

resource "azurerm_lb_rule" "testvmlbrule" {
    loadbalancer_id                = azurerm_lb.TestLB.id
    name                           = "httpin"
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = "PrivateIP"
    backend_address_pool_ids = [azurerm_lb_backend_address_pool.testvmbepool.id ]
}

output Test_LoadBalancer {
    value = "http://${azurerm_lb.TestLB.private_ip_address}"
}

