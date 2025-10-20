

resource "azurerm_policy_definition" "dinesetwebappdeny" {
  name         = "set-webapp-default-deny-public-endpoints-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Sets Webapp Ip Restrictions to Default Deny"
  description  = "Sets Webapp Ip Restrictions to Default Deny"

  policy_rule = file("${path.module}/DeployIfNotExists/set-webapp-default-deny-public-endpoints-restrictions.json")
  parameters = file("${path.module}/DeployIfNotExists/DeployIfNotExist_params.json")

  management_group_id = "/providers/Microsoft.Management/managementGroups/base-group"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  
}



resource "azurerm_policy_definition" "dinesetwebappscmdeny" {
  name         = "set-webapp-scm-default-deny-public-endpoints-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Sets Webapp SCM Ip Restrictions to Default Deny"
  description  = "Sets Webapp SCM Ip Restrictions to Default Deny"

  policy_rule = file("${path.module}/DeployIfNotExists/set-webapp-scm-default-deny-public-endpoints-restrictions.json")
  parameters = file("${path.module}/DeployIfNotExists/DeployIfNotExist_params.json")

  management_group_id = "/providers/Microsoft.Management/managementGroups/base-group"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  
}