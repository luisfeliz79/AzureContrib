resource "azurerm_policy_set_definition" "AuditAppServicePolSet" {
  name         = "Webapps Public Endpoints Restrictions - Audit"
  policy_type  = "Custom"
  display_name = "Webapps Public Endpoints Restrictions - Audit"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  

  policy_definition_reference {
    version              = "1.0.*"
    policy_definition_id = azurerm_policy_definition.auditpolwebapp.id
    parameter_values = <<PARAMETERS
    {
      "effect": {"value": "Audit" }      
    }
    PARAMETERS
  }

    policy_definition_reference {
    version              = "1.0.*"
    policy_definition_id = azurerm_policy_definition.auditpolwebappscm.id
    parameter_values = <<PARAMETERS
    {
      "effect": {"value": "Audit" }      
    }
    PARAMETERS
    }

    policy_definition_reference {
    version              = "1.0.*"
    policy_definition_id = azurerm_policy_definition.auditpolwebappslots.id
    parameter_values = <<PARAMETERS
    {
      "effect": {"value": "Audit" }      
    }   
    PARAMETERS
    }

    policy_definition_reference {
    version              = "1.0.*"  
    policy_definition_id = azurerm_policy_definition.auditpolwebappscmslots.id
    parameter_values = <<PARAMETERS
    {
      "effect": {"value": "Audit" }      
    }
    PARAMETERS
    }




}   