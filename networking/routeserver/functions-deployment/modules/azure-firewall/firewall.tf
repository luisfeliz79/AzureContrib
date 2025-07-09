
resource "azurerm_public_ip" "azure_firewall" {

    name                        = "${var.fw_name}-pip"
    location                    = var.region
    resource_group_name         = var.resource_group_name
    allocation_method           = "Static"
    sku                         = "Standard"
}


resource "azurerm_public_ip" "azure_firewall_mgmt" {  

    name                        = "${var.fw_name}-pip-mgmt"
    location                    = var.region
    resource_group_name         = var.resource_group_name
    allocation_method           = "Static"
    sku                         = "Standard"
}

resource "azurerm_firewall_policy" "child" {

  name                        = "${var.fw_name}-policy"
  location                    = var.region
  resource_group_name         = var.resource_group_name
  sku = "Basic"

  lifecycle {
    ignore_changes = [ insights ]
  }
}


resource "azurerm_firewall" "azure_firewall_instance" {

    name                        = var.fw_name
    location                    = var.region
    resource_group_name         = var.resource_group_name
    sku_name                    = "AZFW_VNet"
    sku_tier                    = "Basic"

    firewall_policy_id          = azurerm_firewall_policy.child.id
    

    ip_configuration {
        name                    = "configuration"
        subnet_id               = var.subnet_fw_id
        public_ip_address_id    = azurerm_public_ip.azure_firewall.id
    }

    management_ip_configuration {
        name                    = "configuration-mgmt"
        subnet_id               = var.subnet_mgmt_id
        public_ip_address_id    = azurerm_public_ip.azure_firewall_mgmt.id
    }

    lifecycle {
      ignore_changes = [ management_ip_configuration[0].subnet_id, ip_configuration[0].subnet_id ]
    }

    timeouts {
      create = "60m"
      delete = "2h"
  }



  depends_on = [    
        azurerm_public_ip.azure_firewall,azurerm_public_ip.azure_firewall_mgmt,
        azurerm_firewall_policy.child
   ]
}

resource "azurerm_firewall_policy_rule_collection_group" "rcg1" {

    name = "default-rcg"
    firewall_policy_id = azurerm_firewall_policy.child.id
    priority = 500

    network_rule_collection {
        name = "internal_nets"
        priority = 500
        action = "Allow"

        rule {
            name = "allow-all-internal-net-traffic"
            source_addresses = ["10.0.0.0/8"]
            destination_addresses = ["10.0.0.0/8"]
            protocols = ["Any"]
            destination_ports = ["*"]            
        }

        rule {
            name = "allow-all-external-net-traffic"
            source_addresses = ["10.0.0.0/8"]
            destination_addresses = ["0.0.0.0/0"]
            protocols = ["Any"]
            destination_ports = ["*"]            
        }
    }
}
