# Create a User Assigned Managed Identity
# Attach the UAMI to the APIM
# Create App Insights Instance and its backend LAW
# Under App Insights IAM, add the UAMI as a Monitoring Metrics Publisher
# Under App Insights Properties, Optionally disable "Local Authentication"
# To add the Logger to APIM, using Managed Identity:
#   Modify the JSON Payload below
#     * identityClientId should be the APPID(ClientID) of the UAMI
#      Note: if using System Assigned Identity instead, use the value: "SystemAssigned"
#     * connectionString is required, and can be sourced from App Insights Overview screen
#     * resourceId is required, and should be the full resource ID of the App Insights instance
#
#   Finally, use PUT method to PUT the json payload to the following URL
#   https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/loggers/{loggerId}?api-version=2023-03-01-preview
#     * loggerId is the name of the logger, which can be any name you want

$json=@'
  {
    "properties": {
      "loggerType": "applicationInsights",
      "description": "Logger for Application Insights",
      "credentials": {
        "identityClientId":"xxxxx-195d-450e-9d70-xxxxxx",
        "connectionString":"InstrumentationKey=xxx-xxx-xxx-xx;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/"      
      },
      "resourceId": "/subscriptions/xxxxxx/resourceGroups/xxxxx/providers/microsoft.insights/components/my-test-ai"
    }
  }
'@

$AccessTokenResult=az account get-access-token
$AccessToken=($AccessTokenResult | ConvertFrom-Json).accessToken

$SubscriptionId="xxxxx-2d2c-4c74-9886-xxxx"
$ResourceGroupName="my-test-rg"
$ServiceName="my-test-apim"
$loggerId="mytestlogger"

$Uri="https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.ApiManagement/service/{2}/loggers/{3}?api-version=2023-03-01-preview" `
     -f $SubscriptionId,$ResourceGroupName,$ServiceName,$loggerId

$headers=@{
    "Content-Type"  = 'application/json'        
    "Authorization" = "Bearer $AccessToken"
}

Invoke-RestMethod -Method PUT -UseBasicParsing -Uri $Uri -Headers $headers -Body $json -ContentType 'application/json'  

