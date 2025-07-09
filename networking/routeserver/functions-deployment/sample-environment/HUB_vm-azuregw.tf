locals {

cloudinit=<<CUSTOM_DATA
#!/bin/bash

sed -i -e '$a\net.ipv4.ip_forward = 1' /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.ip_forward

sudo apt update -y
sudo apt install frr -y
sudo systemctl enable frr
sudo systemctl start frr

sed -i -e 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons
systemctl restart frr

exit 0
CUSTOM_DATA

}

module "azuregw-nva-vm" {
  source = "../modules/vm-linux"

  vm_name = local.vm_azuregw_nva_name
  vm_size = local.vm_size
  vm_admin_username = local.vm_admin_username
  vm_admin_password = local.vm_admin_password
  vm_location = local.region
  vm_rg_name = azurerm_resource_group.azuregw.name
  tags = local.tags
  vm_subnet_id = azurerm_subnet.azuregw-nva.id
  cloudinit = local.cloudinit
  #enable_public_ip = false
  #custom_script_settings = local.vm_settings
}

module "azuregw-nva-vm2" {
  source = "../modules/vm-linux"

  vm_name = local.vm_azuregw_nva2_name
  vm_size = local.vm_size
  vm_admin_username = local.vm_admin_username
  vm_admin_password = local.vm_admin_password
  vm_location = local.region
  vm_rg_name = azurerm_resource_group.azuregw.name
  tags = local.tags
  vm_subnet_id = azurerm_subnet.azuregw-nva.id
  cloudinit = local.cloudinit
  #enable_public_ip = false
  #custom_script_settings = local.vm_settings
}

