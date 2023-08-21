terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = ">= 2.41.0"
    }
  }
}

# Find the Service Principal
data "azuread_service_principal" "AWSAADenterpriseapp" {
  application_id = "4a324055-e4d2-4dc9-84e2-ba4e4b52d775"
}

# Find the Azure AD Group
data "azuread_group" "group1" {
  display_name     = "ZeldaGroup"
  security_enabled = true
}

# Assign the Group to the Service principal's "Users and Groups"
# The app role id is the role id of the app role you want to assign
# You can translate it from display name as shown below
resource "azuread_app_role_assignment" "example" {
  app_role_id         = data.azuread_service_principal.AWSAADenterpriseapp.app_role_ids["arn:aws:iam::587079795251:role/AzureADBoundRole,arn:aws:iam::587079795251:saml-provider/AzureAD"]
  principal_object_id = data.azuread_group.group1.object_id
  resource_object_id  = data.azuread_service_principal.AWSAADenterpriseapp.object_id
}

# Use this for getting the list of roles
output roles {
    value = data.azuread_service_principal.AWSAADenterpriseapp.app_role_ids
}
