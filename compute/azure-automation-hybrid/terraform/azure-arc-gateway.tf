
resource "azapi_resource" "arc_gateway" {
  type                      = "Microsoft.HybridCompute/gateways@2024-07-31-preview"
  name                      = local.arc_gateway_name
  parent_id                 = local.resource_group_id
  location                  = local.location
  schema_validation_enabled = false
  #response_export_values    = ["*"]
  tags                      = local.tags

  body = {
    properties = {
      gatewayType     = "Public"
      allowedFeatures = ["*"]
    }
  }
}
