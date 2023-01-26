variable "location" {
    type = string    
    description = "Deployment region (ex. East US), for supported regions see https://docs.microsoft.com/en-us/azure/spring-apps/faq?pivots=programming-language-java#in-which-regions-is-azure-spring-apps-basicstandard-tier-available"
} 

variable "tags" {
    type        = map 
    default     = { 
        project = "ASA-Accelerator"
    }
}

variable "nva_admin_password" {
    type = string
    sensitive = true    
} 


