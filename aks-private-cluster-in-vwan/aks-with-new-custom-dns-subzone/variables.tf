variable location {
    type = string
    description = "The Azure Region you would like to deploy to"
    default = "eastus2"
}

variable resource_group {
    type = string
    description = "The name of the resource group to be created and deployed to"
    default = "aks-private-cluster-in-vwan"       
}

variable aks_cni_vnet_address_space {
    type = list(string)
    description = "Address space for the VNET supporting this AKS deployment (Azure CNI)"
    default = ["10.6.0.0/16"]   
}

variable aks_cni_subnet_address_space {
    type = list(string)
    description = "Address space for the Subnet supporting this AKS deployment (Azure CNI)"   
    default = ["10.6.0.0/23"]
}

variable central_dns_vnet {
    type = string
    description = "Existing VNET to link the private cluster dns zone to"
    default = "vnet-private-dns-resolver"
}

variable central_dns_vnet_rg {
    type = string
    description = "RG of Existing VNET to link the private cluster dns zone to"
    default = "private-dns-resolver"
}

variable central_dns_privatezones_rg {
    type = string
    description = "RG of Existing Private DNS Zones"
    default = "private-dns-resolver"
}


variable vhub_name {
    type = string
    description = "Existing VHUB name"
    default     = "vwan-hub"   
}

variable vhub_rg {
    type = string
    description = "Existing VHUB RG name"
    default = "vwan-hubrg"   
}


variable custom_dns_servers {
    type = list(string)
    description = "Existing Central DNS IP"
    default = ["10.3.0.4"]   
}

variable vhub_FW_IP {
    type = string
    description = "Existing Azure Firewall or NVA FW IP"
    default = "10.100.2.4"   
}

variable "centralized-dns-subscription" {
    type = string
    description = "Subscription ID for the Centralized DNS Subscription"
    default = "e31e07c8-2d2c-4c74-9886-e6f7d80c9646"   
}

variable "vwan-subscription" {
    type = string
    description = "Subscription ID where the VWAN is deployed"
    default = "e31e07c8-2d2c-4c74-9886-e6f7d80c9646"   
}

variable "custom-dns-subdomain-zone-name" {
    type = string
    description = "the Custom DNS Subdomain name, ex prod.privatelink.eastus2.azmk8s.io"
    default = "prod.privatelink.eastus2.azmk8s.io"   
}
