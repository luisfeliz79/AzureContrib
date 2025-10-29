

resource "azurerm_policy_definition" "auditpolwebapp" {
  name         = "audit-webapps-public-endpoints-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Audit WebApp Public Endpoints Restrictions"
  description  = "Audit WebApp Public Endpoints Restrictions"

  policy_rule = file("${path.module}/Audit-Deny/audit-webapps-public-endpoints-restrictions.json")
  parameters = file("${path.module}/Audit-Deny/Audit_params.json")

  management_group_id = "/providers/Microsoft.Management/managementGroups/base-group"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  
}



resource "azurerm_policy_definition" "auditpolwebappscm" {
  name         = "audit-webapps-scm-public-endpoints-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Audit WebApp SCM Public Endpoints Restrictions"
  description  = "Audit WebApp SCM Public Endpoints Restrictions"

  policy_rule = file("${path.module}/Audit-Deny/audit-webapps-scm-public-endpoints-restrictions.json")
  parameters = file("${path.module}/Audit-Deny/Audit_params.json")

  management_group_id = "/providers/Microsoft.Management/managementGroups/base-group"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  
}