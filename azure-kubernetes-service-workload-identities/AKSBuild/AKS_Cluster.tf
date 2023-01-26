resource "azurerm_kubernetes_cluster" "aksapp" {

  #name is the resource name in Azure
  name                = local.cluster_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  #dns_prefix         = local.cluster_name
  # this will be part of the fqdn of the AKS Server
  dns_prefix          = "aks"

  default_node_pool {
    name            = "defaultpool"
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
    node_count      = 2
    vnet_subnet_id  = azurerm_subnet.spoke_akscni.id
    zones = [1,2,3]
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
   #ignore_changes = all
   ignore_changes = [
     microsoft_defender,
     azure_policy_enabled
   ]
  }

  # support for workload identities
  oidc_issuer_enabled         = true
  workload_identity_enabled   = true

}


output _AKS_Name {
    value = local.cluster_name
}
output _AKS_RG {
    value = local.rg_name
}
output _AKS_FQDN {
    value = "https://${azurerm_kubernetes_cluster.aksapp.fqdn}"
}
