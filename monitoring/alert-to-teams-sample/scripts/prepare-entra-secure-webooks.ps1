$scopes                     = "Application.ReadWrite.All"
$tenantId                   = "<tenant-id>"
$RoleName                   = "SendAlerts"
$WebAppAuthObjectId         = "<the-object-id-of-the-webapp-auth-app-registration>"
$MicrosoftActionsGroupClientId = "461e8683-5575-4561-ac7f-899cc907d62a" # Required. Do not change.

# This code will connect to MS Graph and ..
#  Onboard the Azure Monitor Action Groups service principal to the tenant
#  Give the Azure Monitor Action Groups service principal permission
#  to call the Webapp via the app role assignment.

Connect-MgGraph -Scopes $scopes -TenantId $tenantId

# Get the App registration and Service Principal for the Web App Authentication SP
# and its existing roles

try {
    $WebAppAppReg = Get-MgApplication -ApplicationId $WebAppAuthObjectId -ErrorAction Stop
    $WebAppSP = Get-MgServicePrincipal -Filter "appId eq '$($WebAppAppReg.AppId)'" -ErrorAction Stop
    $WebAppAppRegRoles = $WebAppAppReg.AppRoles | Where-Object { $_.Value -eq $RoleName } -ErrorAction Stop
} catch {
    if ($null -eq $WebAppAppReg ) {Write-host "Could not find an App Reg with Object ID $WebAppAuthObjectId, breaking.";break}
    if ($null -eq $WebAppAppRegRoles ) {Write-host "Could not find the App Role $RoleName in the App Registration, breaking.";break}
    if ($null -eq $WebAppSP ) {Write-host "Could not find a Service Principal for the App Registration, breaking.";break}
    $_
    break
}

# Get the Enterprise Application (Service Principal) for Azure Monitor Action Groups service
$MicrosoftActionsGroupSPN = Get-MgServicePrincipal -Filter "appId eq '$MicrosoftActionsGroupClientId'"



# Check if the Enterprise app already exists, if not create it.
if ($MicrosoftActionsGroupSPN.DisplayName -contains "AzNS AAD Webhook") {
    Write-Host "The Service principal is already defined.`n"
    Write-Host "The action group Service Principal is: $($MicrosoftActionsGroupSPN.DisplayName) and the id is: $($MicrosoftActionsGroupSPN.Id)"
}
else {
    Write-Host "The Service principal has NOT been defined/created in the tenant.`n"
    $MicrosoftActionsGroupSPN = New-MgServicePrincipal -AppId $MicrosoftActionsGroupClientId
    Write-Host "The Service Principal is been created successfully, and the id is: " + $MicrosoftActionsGroupSPN.Id
}


# Check if the Role assignment already exists, if not create it.
$existingRoleAssignment = Get-MgServicePrincipalAppRoleAssignment `
        -ServicePrincipalId $MicrosoftActionsGroupSPN.Id | Where-Object { $_.AppRoleId -eq $WebAppAppRegRoles.Id -and $_.PrincipalId -eq $MicrosoftActionsGroupSPN.Id -and $_.ResourceId -eq $WebAppSP.Id }

if ($null -eq $existingRoleAssignment) {
    Write-Host "Doing app role assignment to the new action group Service Principal`n"
    New-MgServicePrincipalAppRoleAssignment `
        -ServicePrincipalId $MicrosoftActionsGroupSPN.Id `
        -AppRoleId $WebAppAppRegRoles.Id  `
        -PrincipalId $MicrosoftActionsGroupSPN.Id `
        -ResourceId $WebAppSP.Id
}
else {
    Write-Host "Skip assigning because the role already existed."
}

Write-Host "`nScript execution completed."




