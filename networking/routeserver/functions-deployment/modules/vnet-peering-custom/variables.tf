variable "left_vnet_object" {
    description = "The object of the spoke vnet"
}

variable "right_vnet_object" {
    description = "The object of the spoke vnet"
}

variable "left_subscription_id" {
    description = "The Sub id of the vnet"
}

variable "right_subscription_id" {
    description = "The Sub id of the vnet"
}

variable "allow_gateway_transit" {
    description = "Allow gateway transit"
    default = false
    type = bool
}

variable "use_remote_gateways" {
    description = "Allow gateway transit"
    default = false
    type = bool
}
