

resource "azurerm_policy_definition" "auditpolwebappslots" {
  name         = "audit-webapps-slots-public-endpoints-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Audit WebApp Slots Public Endpoints Restrictions"
  description  = "Audit WebApp Slots Public Endpoints Restrictions"

  policy_rule = file("${path.module}/Audit-Deny/audit-webapps-slots-public-endpoints-restrictions.json")
  parameters = file("${path.module}/Audit-Deny/Audit_params.json")

  management_group_id = "/providers/Microsoft.Management/managementGroups/base-group"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  
}



resource "azurerm_policy_definition" "auditpolwebappscmslots" {
  name         = "audit-webapps-slots-scm-public-endpoints-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Audit WebApp Slots SCM Public Endpoints Restrictions"
  description  = "Audit WebApp Slots SCM Public Endpoints Restrictions"

  policy_rule = file("${path.module}/Audit-Deny/audit-webapps-slots-scm-public-endpoints-restrictions.json")
  parameters = file("${path.module}/Audit-Deny/Audit_params.json")

  management_group_id = "/providers/Microsoft.Management/managementGroups/base-group"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  
}