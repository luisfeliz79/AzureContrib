variable "name" {
  description = "The name of the route server."
  type        = string
}

variable "region" {
  description = "The Azure region where the resources will be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the resources will be created."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the route server will be deployed."
  type        = string
}
variable "tags" {
  description = "Tags to be applied to the resources."
  type        = map(string)
  default     = {}
}

variable "enable_branch_to_branch_traffic" {
  description = "Whether to enable branch-to-branch traffic."
  type        = bool
  default     = true
}

variable "list_of_bgp_connections" {
  description = "List of BGP connections to be created for the route server."
  type = list(object({
    name     = string
    peer_asn = number
    peer_ip  = string
  }))
  default = []
}