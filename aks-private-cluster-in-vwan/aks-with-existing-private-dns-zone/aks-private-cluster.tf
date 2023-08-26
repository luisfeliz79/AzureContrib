# In this scenario, there customer is using a centralized DNS Solution
# running in a separate Azure Subscription


# Get info about existing Private DNS Zone
data "azurerm_private_dns_zone" "aks-dns" {

    provider = azurerm.centralized-dns-subscription
    
    name                = var.custom-dns-subdomain-zone-name
    resource_group_name = var.central_dns_privatezones_rg
}

# RBAC for the Custom DNS Zone
resource "azurerm_role_assignment" "aks-to-dnszone" {  
  scope                = data.azurerm_private_dns_zone.aks-dns.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.uaid1.principal_id
}

# RBAC for the Spoke Virtual Network
resource "azurerm_role_assignment" "aks-to-vnet" {  
  scope                = azurerm_virtual_network.spoke_vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.uaid1.principal_id
}

resource "azurerm_kubernetes_cluster" "akscluster" {
  
  name                = local.cluster_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  private_cluster_enabled             = true
  private_dns_zone_id                 = data.azurerm_private_dns_zone.aks-dns.id 
  private_cluster_public_fqdn_enabled = false

  dns_prefix          = "aks"

  default_node_pool {
    name            = "defaultpool"
    vm_size         = "Standard_B2as_v2"
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
    node_count      = 2
    vnet_subnet_id  = azurerm_subnet.spoke_akscni.id
    zones = [1,2,3]
  }

  network_profile {
    network_plugin     = "azure"
    outbound_type      = "userDefinedRouting"
    dns_service_ip     = "192.168.100.10"
    service_cidr       = "192.168.100.0/24"
    docker_bridge_cidr = "172.17.0.1/16"
  }
  
  role_based_access_control_enabled = true

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uaid1.id]
  }

  depends_on = [
    # needed because AKS creation checks for Route table
    azurerm_subnet_route_table_association.FWRouteAssoc,

    # needed for DNS resolution
    azurerm_role_assignment.aks-to-dnszone,
    
    # Needed to establish the connection to the VWAN
    azurerm_virtual_hub_connection.hubconnection
  ]

  lifecycle {  
   ignore_changes = [
     default_node_pool
   ]
  }



}
