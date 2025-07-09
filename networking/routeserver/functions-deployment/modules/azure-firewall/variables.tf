variable "fw_name" {
  description = "The name of the Azure Firewall"
  type        = string
}

variable "region" {
  description = "The Azure region where the resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "subnet_fw_id" {
  description = "The ID of the subnet for the Azure Firewall"
  type        = string
}

variable "subnet_mgmt_id" {
  description = "The ID of the management subnet for the Azure Firewall"
  type        = string
}
variable "tags" {
  description = "A map of tags to assign to the Azure Firewall resources"
  type        = map(string)
  default     = {}
}