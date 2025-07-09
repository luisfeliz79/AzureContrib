
locals {

  map_of_vnet_ids = zipmap(tolist(range(length(var.vnet_ids))), var.vnet_ids)
  
}

resource "azurerm_private_dns_zone" "zone" {
  name                      = var.zone_name
  resource_group_name       = var.zone_rg
}

# Private DNS Zones links
resource "azurerm_private_dns_zone_virtual_network_link" "links" {

    # for each vnet ID in the list, create a link
    for_each = local.map_of_vnet_ids

    name                  = "${split("/", each.value)[8]}"
    resource_group_name   = var.zone_rg
    private_dns_zone_name = azurerm_private_dns_zone.zone.name
    virtual_network_id    = each.value

    depends_on = [ azurerm_private_dns_zone.zone ]
}
