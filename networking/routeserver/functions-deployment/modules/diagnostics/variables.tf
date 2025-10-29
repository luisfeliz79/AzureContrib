variable "target_resource_id" {
  description = "The ID of the resource to be monitored."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace to send logs to."
  type        = string
}

# variable "log_categories" {
#   description = "List of log categories to enable."
#   type        = list(string)
#   default     = []
# }