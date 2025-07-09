variable "zone_name" {
  description = "The name of the private DNS zone"
  type        = string
}
variable "zone_rg" {
  description = "The resource group name for the private DNS zone"
  type        = string
}

# list of vnet IDs to link the private DNS zone to
variable "vnet_ids" {
  description = "List of virtual network IDs to link the private DNS zone to"
  type        = list(string)
}
