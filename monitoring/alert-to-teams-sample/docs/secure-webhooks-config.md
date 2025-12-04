# WIP

## Enabling Secure Webhooks and Authentication for the logic app

To enable secure webhooks and authentication for the Logic App that sends alerts to Microsoft Teams, follow these steps:

Requirements:
- An Entra ID application (App Registration)
- The setup account must be an owner of the application
- The Azure Monitor Action Groups SPN must be registered in the Entra ID tenant
("AzNS AAD Webhook", AppId: 461e8683-5575-4561-ac7f-899cc907d62a)


## Setup steps:
### Configure the Entra ID Application: 
   - Navigate to "Entra ID" > "App registrations" > and select the application
    - Under "Authentication", add a platform for "Web" and set the redirect URI to the Logic App's callback URL
    https://<logic-app-name>.azurewebsites.net/.auth/login/aad/callback
    - Under Expose an API, click "Add" next to "Application ID URI" and keep the auto-generated value
    - Under App Roles, create a new app role with the following settings:
        - Display name: SendAlerts
        - Allowed member types: Applications
        - Value: SendAlerts
        - Description: Allows access to the send alerts endpoint
### Allow the Azure Monitor Action Groups SPN to access the application:
Note: this has to be done programmatically using Microsoft Graph API or Azure CLI, as the portal does not support this currently.

Your logged in account must have owner access to the service principal of your application.

   - Using Azure CLI, run the following command:
   ```bash

  Your_Entra_ID_Application_ObjectId="xxxxx"

  # Obtain the information needed to create the app role assignment. Note do not change the id below, it is the same for all tenants  
  AzNS_AAD_Webhook_ObjectId=$(az ad sp show --id 461e8683-5575-4561-ac7f-899cc907d62a --query id -o tsv)

  Your_Entra_ID_Application_ClientId=$(az ad app show --id $Your_Entra_ID_Application_ObjectId --query appId -o tsv)

  Your_Entra_ID_ServicePrincipalId=$(az ad sp show --id $Your_Entra_ID_Application_ClientId --query id -o tsv)

  SendAlerts_AppRoleId=$(az ad app show --id $Your_Entra_ID_Application_ObjectId --query appRoles[?[].value=='SendAlerts'].id -o tsv)

  echo "AzNS_AAD_Webhook_ObjectId: $AzNS_AAD_Webhook_ObjectId"
  echo "Your_Entra_ID_Application_ObjectId: $Your_Entra_ID_Application_ObjectId"
  echo "Your_Entra_ID_Application_ClientId: $Your_Entra_ID_Application_ClientId"
  echo "Your_Entra_ID_ServicePrincipalId: $Your_Entra_ID_ServicePrincipalId"
  echo "SendAlerts_AppRoleId: $SendAlerts_AppRoleId" 


   az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/${AzNS_AAD_Webhook_ObjectId}/appRoleAssignments" --body "{
       \"principalId\": \"${AzNS_AAD_Webhook_ObjectId}\",
       \"resourceId\": \"${Your_Entra_ID_ServicePrincipalId}\",
       \"appRoleId\": \"${SendAlerts_AppRoleId}\"
   }" --headers "Content-Type=application/json"
   ```
   Replace `{AzNS_AAD_Webhook_ObjectId}` with the object ID of the Azure Monitor Action Groups SPN, `{Your_Entra_ID_Application_ObjectId}` with the object ID of your Entra ID application, and `{SendAlerts_AppRoleId}` with the app role ID created in the previous step. 
### Configure the Logic App Authentication settings:
   - In the Azure Portal, navigate to your Logic App
   - Under "Authentication", click Add Identity Provider
   - select "Microsoft" for Identity Provider
   - Select "Pick an existing app registration in the directory" and choose your Entra ID application
   - Select Client Secret expiration (a secret will automatically be created and managed by the Logic App)
   Under issuer URL, enter (replace TenantId with your Entra ID tenant ID):
   `https://login.microsoftonline.com/{TenantId}/v2.0`
   - Under Additional checks
        - Client Application requirement: Allow requests only from the following client applications
        - Under Allowed client Applications: 461e8683-5575-4561-ac7f-899cc907d62a
        - Identity Requirement: Allow requests from specified identities
        - Allowed Identities: `<The objectID of the "AzNS AAD Webhook" service principal>`
        - Tenant requirement: Allow requests only from the issuer tenant (xxxx)
    
    - Excluded paths : keep the default (/runtime/*)

    - Under App Service authentication settings
        - Restrict access: Require authentication
        - Unauthenticated requests: Return 401 Unauthorized
        - Token store: Unchecked
    - Click Add

### Update the Action Group to use the secure webhook
WIP




