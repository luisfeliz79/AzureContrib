resource "azurerm_resource_group_template_deployment" "teams-api-connection" {
  name                = "logicapps-deployment-api-connection-teams"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode(
    {
      name = {
        value = "teams"
      },
      location = {
        value = azurerm_resource_group.rg.location
      }
    }
  )
  template_content = <<TEMPLATE
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "name": {
            "defaultValue": "teams",
            "type": "String"
        },
        "location": {
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Web/connections",
            "apiVersion": "2016-06-01",
            "name": "[parameters('name')]",
            "location": "[parameters('location')]",
            "kind": "V2",
            "properties": {
                "displayName": "teams",
                "api": {
                  "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/', 'teams')]"
                }

            }
        }
    ],
    "outputs": {
    "connectionRuntimeUrl": {
        "type": "String",
        "value": "[reference(resourceId('Microsoft.Web/connections', parameters('name'))).connectionRuntimeUrl]"
      }
    }
}

TEMPLATE

}

resource "azurerm_resource_group_template_deployment" "teams-api-connection-access-policy" {
  name                = "logicapps-deployment-api-connection-teams-access-policy"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode(
    {
      name = {
        value = "teams"
      },
      location = {
        value = azurerm_resource_group.rg.location
      },
      connection_name = {
        value = "${azurerm_logic_app_standard.logicapp.name}-connection"
      },
      connection_object_id = {
        value = azurerm_logic_app_standard.logicapp.identity[0].principal_id
      },
      connection_tenant_id = {
        value = azurerm_logic_app_standard.logicapp.identity[0].tenant_id
      }
    }
  )
  template_content = <<TEMPLATE
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "name": {
            "defaultValue": "teams",
            "type": "String"
        },
        "location": {
            "type": "String"
        },
        "connection_name": {
            "type": "String"
        },
        "connection_object_id": {
            "type": "String"
        },
        "connection_tenant_id": {
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        {
          "type": "Microsoft.Web/connections/accessPolicies",
          "apiVersion": "2018-07-01-preview",
          "name": "[concat(parameters('name'),'/',parameters('connection_name'))]",
          "location": "[resourceGroup().location]",

          "properties": {
            "principal": {
              "type": "ActiveDirectory",
              "identity": {
                "objectId": "[parameters('connection_object_id')]",
                "tenantId": "[parameters('connection_tenant_id')]"
              }
            }
          }
        }
    ]
}

TEMPLATE

  depends_on = [ azurerm_resource_group_template_deployment.teams-api-connection ]

}