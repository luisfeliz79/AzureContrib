# The Spoke VNET 
resource "azurerm_virtual_network" "spoke_vnet" {
    name                        = "vnet-${local.cluster_name}"
    location                    = local.location 
    resource_group_name         = azurerm_resource_group.rg.name
    address_space               = var.aks_cni_vnet_address_space

    dns_servers                 = var.custom_dns_servers
}

# Create a Subnet for AKS CNI
resource "azurerm_subnet" "spoke_akscni" {
  name                      = "snet-akscni"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  address_prefixes          = var.aks_cni_subnet_address_space
}


# This route table needs to be in place when AKS outboundType=UserDefinedRouting
# https://learn.microsoft.com/en-us/azure/aks/egress-udr#deploy-a-cluster-with-outbound-type-of-udr-and-azure-firewall
resource "azurerm_route_table" "FWRoute" {
  name                          = "route-to-firewall"
  location                      = local.location 
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "Default_to_Internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.vhub_FW_IP
  }

  lifecycle {
    ignore_changes = all
  }

}

resource "azurerm_subnet_route_table_association" "FWRouteAssoc" {
  subnet_id      = azurerm_subnet.spoke_akscni.id  
  route_table_id = azurerm_route_table.FWRoute.id
}
