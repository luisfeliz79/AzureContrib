
locals {

    subscription_id = "<subscription-id>"
    region         = "eastus2"

    include_firewall = true
    include_vnetgw = true
    include_route_server = true

    # This simulations onprem routers
    onprem_vnet_cidr                   = "10.75.0.0/16"
    onprem_subnet_nva_cidr             = "10.75.0.0/24"
    onprem_subnet_client_cidr          = "10.75.1.0/24"
    
    # This is the HUB Net where GW, NVAs, and RS live
    azuregw_vnet_cidr                  = "10.80.0.0/16"
    azuregw_subnet_nva_cidr            = "10.80.0.0/24"
    azuregw_subnet_routeserver_cidr    = "10.80.1.0/24" 
    azuregw_subnet_vnetgw_cidr         = "10.80.99.0/24"
    azuregw_subnet_appsvc_cidr         = "10.80.2.0/24" 
    azuregw_subnet_endpoints_cidr      = "10.80.3.0/24" 

    # # what is this?
    # azurenet1_vnet_cidr                = "10.79.0.0/16"
    # azurenet1_subnet_client_cidr       = "10.79.0.0/25"
    # azurenet1_subnet_nva_cidr          = "10.79.5.0/25"
    # azurenet1_subnet_nvaint_cidr       = "10.79.3.0/25"

    # This is the FW VNET and the real Hub for the spokes
    azurefwhub_vnet_cidr                 = "10.81.0.0/16"
    azurefwhub_subnet_firewall_cidr      = "10.81.0.0/25"
    azurefwhub_subnet_firewallmgmt_cidr  = "10.81.128.0/25"
    azurefwhub_subnet_client_cidr        = "10.81.1.0/24"

    # This is a spoke net
    azurespoke_vnet_cidr                 = "10.82.0.0/16"
    azurespoke_subnet_default_cidr       = "10.82.1.0/24"
    azurespoke_subnet_endpoints_cidr     = "10.82.2.0/24"

    vm_azurenet1_nva_name       = "azurenet1nva1"
    vm_azurenet1_nva_name2      = "azurenet1client" 
    vm_onprem_nva_name          = "onpremnva"
    vm_onprem_client_name       = "onpremclient"
    vm_azuregw_nva_name         = "azuregwnva"
    vm_azuregw_nva2_name        = "azuregwnva2"
    vm_azurespoke_client_name   = "spokeclient"
    vm_azurefwhub_client_name   = "fwhubclient"    
    vm_admin_username           = "luisadmin"        # Admin username for the VM
    vm_admin_password           = module.read_password.value
    vm_size                     = "Standard_B2s_v2" # Size of the VM 

    rs_azuregw_name             = "azuregw-routeserver"

    gw_azuregw_vnetgw_name      = "azuregw-vnetgw"
    fw_azurefwhub_name          = "azurefwhub-firewall"

    user_ip_address             = "162.226.7.217"
    FW_IP                       = "10.81.0.4"
    LB_IP                       = "10.79.5.4"
    NVA_INT_IP                  = "10.79.3.4"
    ONPREM_RTR_IP               = "10.75.0.4"

    support_storageaccount_name   = "sa${random_string.suffix.result}${local.region}"
    support_loganalytics_name     = "law${random_string.suffix.result}${local.region}"
    support_appinsights_name      = "ai${random_string.suffix.result}${local.region}"


    tags = {
        environment = "routeserver"
    }
}
