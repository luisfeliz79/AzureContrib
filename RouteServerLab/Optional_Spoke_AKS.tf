resource "azurerm_kubernetes_cluster" "aksapp" {
  name                = "rslabaks"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  dns_prefix          = "rslabaks"

  default_node_pool {
    name            = "defaultpool"
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
    node_count      = 1
    vnet_subnet_id  = azurerm_subnet.spoke_Apps.id
  }

  network_profile {
    network_plugin = "azure"
    
    dns_service_ip = "192.168.100.10"
    service_cidr = "192.168.100.0/24"
    docker_bridge_cidr = "172.17.0.1/16"

  }
  
  role_based_access_control_enabled = true

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = all
  }

}

# output TEST_AKS {
#     value = "https://${azurerm_kubernetes_cluster.aksapp.fqdn}"
# }