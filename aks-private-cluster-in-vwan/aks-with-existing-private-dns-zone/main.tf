
resource "random_string" "suffix" {
  length = 5
  upper = false
  special = false
}

locals  {
  location            = var.location
  rg_name             = var.resource_group
  cluster_name        = "aks${random_string.suffix.result}"
}

# Resource groups 
resource "azurerm_resource_group" "rg" {
    name                        = local.rg_name
    location                    = local.location
}