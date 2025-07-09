variable "zone_rg" {
  description = "The resource group name for the private DNS zone"
  type        = string
}

variable "sa_name" {
  description = "The name of the storage account"
  type        = string
}
variable "sa_id" {
  description = "The ID of the storage account"
  type        = string
}
variable "region" {
  description = "The Azure region where the resources will be created"
  type        = string
}
variable "endpoints_subnet_id" {
  description = "The ID of the subnet where the private endpoints will be created"
  type        = string
}
variable "resource_group_name" {
  description = "The name of the resource group where the private endpoints will be created"
  type        = string
}
variable "tags" {
  description = "Tags to be applied to the resources"
  type        = map(string)
  default     = {}
}
