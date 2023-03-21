variable location {
    type = string
    description = "The Azure Region you would like to deploy to"
    default = "eastus"
}

variable resource_group {
    type = string
    description = "The name of the resource group to be created and deployed to"   
}

variable aks_cni_vnet_address_space {
    type = list(string)
    description = "Address space for the VNET supporting this AKS deployment (Azure CNI)"
    default = ["10.230.0.0/16"]   
}

variable aks_cni_subnet_address_space {
    type = list(string)
    description = "Address space for the Subnet supporting this AKS deployment (Azure CNI)"   
    default = ["10.230.0.0/24"]
}



