resource "azurerm_policy_set_definition" "AppServicePolSet" {
  name         = "Webapps Public Endpoints Restrictions"
  policy_type  = "Custom"
  display_name = "Webapps Public Endpoints Restrictions"

  metadata = <<METADATA
  {
    "category": "Luis"
  }
  METADATA  

    policy_definition_reference {
        version              = "1.0.*"  
        policy_definition_id = azurerm_policy_definition.dinesetwebappdeny.id
        parameter_values = <<PARAMETERS
        {
        "effect": {"value": "DeployIfNotExists" }      
        }
        PARAMETERS
    }

    policy_definition_reference {
        version              = "1.0.*"  
        policy_definition_id = azurerm_policy_definition.dinesetwebappscmdeny.id
        parameter_values = <<PARAMETERS
        {
        "effect": {"value": "DeployIfNotExists" }      
        }
        PARAMETERS
    }

    policy_definition_reference {
        version              = "1.0.*"  
        policy_definition_id = azurerm_policy_definition.dinesetwebappslotsdeny.id
        parameter_values = <<PARAMETERS
        {
        "effect": {"value": "DeployIfNotExists" }      
        }
        PARAMETERS
    }

    policy_definition_reference {
        version              = "1.0.*"  
        policy_definition_id = azurerm_policy_definition.dinesetwebappslotsscmdeny.id
        parameter_values = <<PARAMETERS
        {
        "effect": {"value": "DeployIfNotExists" }      
        }
        PARAMETERS
    }


}   