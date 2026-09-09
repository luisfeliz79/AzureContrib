# WORK IN PROGRESS
# Using an SP for Graph Notifications administration
A service principal used for Graph Notification administration must have access to the resources notifications are being configured for.  For example, in the case of Exchange messages and calendar events, the SP must have Calendars.Read and Mail.Read application permissions.

In addition, it is recommended to use a certificate credentials for the service principal instead of client secrets, as this provides a more secure authentication method.


## Create a service principal with a certificate

1) Create the SP
    ```
    # Create App Registration
    az ad sp create-for-rbac --create-cert --name "MSGraph-Change-Notification-Admin"
    ```

2) Grab the App ID and Tenant Information

3) Save the certificate information for later use.  This will be used to authenticate your scripts to the Graph Service. For easy copy/paste of the certificate credentials, use the cat command.
    ```bash
    cat /path/to/certificate.pem
    ```

## Configure the needed Application Permissions

```
# Your SPN's object (principal) ID
$spId = az ad sp show --id "$Spn" --query id -o tsv
$spId
# Microsoft Graph service principal object ID in your tenant
$graphId = az ad sp show --id "00000003-0000-0000-c000-000000000000" --query id -o tsv
$graphId


# Mail.Read
az rest --method POST `
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$spId/appRoleAssignments" `
  --headers "Content-Type=application/json" `
  --body "{`"principalId`":`"$spId`",`"resourceId`":`"$graphId`",`"appRoleId`":`"810c84a8-4a9e-49e6-bf7d-12d183f40d01`"}"

# Calendars.Read
az rest --method POST `
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$spId/appRoleAssignments" `
  --headers "Content-Type=application/json" `
  --body "{`"principalId`":`"$spId`",`"resourceId`":`"$graphId`",`"appRoleId`":`"798ee544-9d2d-430c-a058-570e29e34338`"}"

```




## Configure Permissions In Microsoft Exchange (Messages and Calendar)
This portion requires the Exchange Online PowerShell module.

```
# Exchange Online process

# Run this at least once in the tenant
# ref: https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/enable-organizationcustomization?view=exchange-ps
Enable-OrganizationCustomization


# Create a management scope
#ref: https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/new-managementscope?view=exchange-ps

New-ManagementScope -Name GraphNotifyScope -RecipientRestrictionFilter "Name -Like 'Luis*'"


NOTE: 
##############
# In ENTRA ID, get added to role Exchange Administrator
################################

# Define Application info

$SpnAppId="xxxxxx"
$SpnOid="xxxxxxx" (From Enterprise Applications)
$SpName="MSGraph-Change-Notification-Admin"

# Load up and connect Exchange module
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Add the application to Exchange (from EntraID)
New-ServicePrincipal -AppId $SpnAppId -ObjectId $SpnOid -DisplayName $SpName

# Create the Role assignments
New-ManagementRoleAssignment -App $SpnAppId -Role "Application Calendars.Read" -CustomResourceScope "GraphNotifyScope"

New-ManagementRoleAssignment -App $SpnAppId -Role "Application Mail.Read" -CustomResourceScope "GraphNotifyScope"   

# Run a test 
Test-ServicePrincipalAuthorization -Identity $SpnAppId -Resource test-username
```


Ref: https://learn.microsoft.com/en-us/exchange/permissions-exo/application-rbac?toc=/graph/toc.json
[Role Based Access Control for Applications in Exchange Online | Microsoft Learn](https://learn.microsoft.com/en-us/exchange/permissions-exo/application-rbac)

