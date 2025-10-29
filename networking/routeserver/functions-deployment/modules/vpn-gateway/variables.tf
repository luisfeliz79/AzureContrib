variable "name" {
  description = "The name of the VPN Gateway."
  type        = string
}

variable "region" {
  
}
variable "resource_group_name" {
  description = "The name of the resource group where the VPN Gateway will be created."
  type        = string  
}

variable "gateway_subnet_id"    {
  description = "The ID of the subnet where the VPN Gateway will be deployed."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the VPN Gateway."
  type        = map(string)
  default     = {}
}

variable "ONPREM_RTR_IP" {
  description = "The IP address of the on-premises router for BGP peering."
  type        = string
}

variable "shared_key" {
  description = "The shared key for the VPN connection."
  type        = string
  default     = "P@ssw0rd1234"
}

variable "VM_PUBLIC_IP" {
  description = "The public IP address of the on-premises virtual machine for BGP peering."
  type        = string
  
}
