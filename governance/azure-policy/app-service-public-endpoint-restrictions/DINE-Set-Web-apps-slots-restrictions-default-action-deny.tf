

resource "azurerm_policy_definition" "dinesetwebappslotsdeny" {
  name         = "set-webapp-slots-default-deny-public-endpoints-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Sets Webapp Slots Ip Restrictions to Default Deny"
  description  = "Sets Webapp Slots Ip Restrictions to Default Deny"

  policy_rule = file("${path.module}/DeployIfNotExists/set-webapp-slots-default-deny-public-endpoints-restrictions.json")
  parameters = file("${path.module}/DeployIfNotExists/DeployIfNotExist_params.json")

  management_group_id = "/providers/Microsoft.Management/managementGroups/base-group"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  
}



resource "azurerm_policy_definition" "dinesetwebappslotsscmdeny" {
  name         = "set-webapp-slots-scm-default-deny-public-endpoints-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Sets Webapp Slots SCM Ip Restrictions to Default Deny"
  description  = "Sets Webapp Slots SCM Ip Restrictions to Default Deny"

  policy_rule = file("${path.module}/DeployIfNotExists/set-webapp-slots-scm-default-deny-public-endpoints-restrictions.json")
  parameters = file("${path.module}/DeployIfNotExists/DeployIfNotExist_params.json")

  management_group_id = "/providers/Microsoft.Management/managementGroups/base-group"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  
}