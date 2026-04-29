variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace where the custom table will be created."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace where the custom table will be created."
  type        = string
}

variable "custom_table_name" {
  description = "The name of the custom table to be created in the Log Analytics Workspace."
  type        = string
  default     = "Custom_CL"
}

variable "custom_table_columns" {
  description = "The columns to be created in the custom table."
  type        = list(object({
    name = string
    type = string
  }))

  default = [
    {
      name = "TimeGenerated"
      type = "DateTime"
    },
    {
      name = "RawData"
      type = "String"
    }
  ]
}



################
variable "region" {
  description = "The Azure region where the resources will be created."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "The name of the resource group where the Log Analytics Workspace is located."
  type        = string
  
}

variable "dce_name" {
  description = "The name of the Data Collection Endpoint (DCE) to be created."
  type        = string
  default     = "dce-custom-log"
  
}
variable "dcr_name" {
  description = "The name of the Data Collection Rule (DCR) to be created."
  type        = string
  default     = "dcr-custom-log"
}