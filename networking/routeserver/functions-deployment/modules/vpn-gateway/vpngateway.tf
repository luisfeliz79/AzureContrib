resource "azurerm_public_ip" "gwlabpip1" {

  name                = "${var.name}-ip1"
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = [1,2,3]
}

resource "azurerm_public_ip" "gwlabpip2" {

  name                = "${var.name}-ip2"
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  zones = [1,2,3]
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway
resource "azurerm_virtual_network_gateway" "gw1" {

  name                = var.name
  location            = var.region
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  bgp_enabled   = true
  sku           = "VpnGw1AZ"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.gwlabpip1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.gwlabpip2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

    bgp_settings {
      asn = 65510
    }

  tags = var.tags
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection
resource "azurerm_local_network_gateway" "onpremise" {

  name                = "onpremise"
  location            = var.region
  resource_group_name = var.resource_group_name
  gateway_address     = var.VM_PUBLIC_IP
  address_space       = ["${var.ONPREM_RTR_IP}/32"]
  
  bgp_settings {
        asn = 65502
        bgp_peering_address = var.ONPREM_RTR_IP
  }
}


resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  name                = "onpremise"
  location            = var.region
  resource_group_name = var.resource_group_name

  #enable_bgp = true
  bgp_enabled = true

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gw1.id
  local_network_gateway_id   = azurerm_local_network_gateway.onpremise.id

  shared_key = var.shared_key

  lifecycle {
    ignore_changes = [ shared_key ]
  }

  ipsec_policy {
    dh_group = "DHGroup14"
    ike_encryption = "AES256"
    ike_integrity = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity = "SHA256"
    pfs_group = "PFS2048"
    sa_lifetime = "43200"
  }

  dpd_timeout_seconds = 45

  
}
