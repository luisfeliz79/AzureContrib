
# Role assignment - Needs a user with Root owner access
function Assign-MonitoredObjectsContributorRole($UserObjectID) {
  New-AzRoleAssignment -Scope '/providers/Microsoft.Insights' -RoleDefinitionName 'Monitored Objects Contributor' -ObjectId $UserObjectID
}
# Needs GA
function Unassign-MonitoredObjectsContributorRole($UserObjectID) {
  Remove-AzRoleAssignment -Scope '/providers/Microsoft.Insights' -RoleDefinitionName 'Monitored Objects Contributor' -ObjectId $UserObjectID
}
#Need GA
function List-MonitoredObjectsRoleAssignments() {
  $requestURL = "https://management.azure.com/providers/Microsoft.Insights/providers/microsoft.authorization/roleassignments`?api-version=2021-04-01-preview"
  Get-AzRoleAssignment -Scope '/providers/Microsoft.Insights' 
  #| select RoleAssignmentName,SigninName,RoleDefinitionName,Scope
}

# Monitored Object
function List-MonitoredObjects($TenantId, $Location = "eastus2") {

  if (-not $TenantId) {
    throw "TenantID is required"
  }
  
  $auth = Get-AzAccessToken -AsSecureString
  $AuthenticationHeader = @{
      "Content-Type" = "application/json"
      "Authorization" = "Bearer " + $(ConvertFrom-SecureString $auth.Token -AsPlainText)
  }
  


  $requestURL = "https://management.azure.com/providers/Microsoft.Insights/monitoredObjects/$TenantID`?api-version=2021-09-01-preview"
  Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method get -ErrorAction SilentlyContinue
}
function Create-MonitoredObjects($TenantId, $Location = "eastus2") {

  if (-not $TenantId) {
    throw "TenantID is required"
  }
  
  $auth = Get-AzAccessToken -AsSecureString
  $AuthenticationHeader = @{
      "Content-Type" = "application/json"
      "Authorization" = "Bearer " + $(ConvertFrom-SecureString $auth.Token -AsPlainText)
  }
  
  $requestURL = "https://management.azure.com/providers/Microsoft.Insights/monitoredObjects/$TenantID`?api-version=2021-09-01-preview"
  $body = @{properties=@{location="$Location"}} | ConvertTo-Json
  Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method PUT -Body $body
}
function Remove-MonitoredObjects($TenantId) {

  if (-not $TenantId) {
    throw "TenantID is required"
  }
  
  $auth = Get-AzAccessToken -AsSecureString
  $AuthenticationHeader = @{
      "Content-Type" = "application/json"
      "Authorization" = "Bearer " + $(ConvertFrom-SecureString $auth.Token -AsPlainText)
  }
  

  $requestURL = "https://management.azure.com/providers/Microsoft.Insights/monitoredObjects/$TenantID`?api-version=2021-09-01-preview"
  Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method DELETE
}

# Associations
function Add-MonitoredObjectsDCRAssociation($TenantID, $associationName, $DCRId) {

  if (-not $TenantId) {
    throw "TenantID is required"
  }
  if (-not $associationName) {
    throw "associationName is required"
  }
  if (-not $DCRId) {
    throw "DCRId is required"
  }

  $auth = Get-AzAccessToken -AsSecureString
  $AuthenticationHeader = @{
      "Content-Type" = "application/json"
      "Authorization" = "Bearer " + $(ConvertFrom-SecureString $auth.Token -AsPlainText)
  }
  

  $requestURL = "https://management.azure.com/providers/Microsoft.Insights/monitoredObjects/$TenantID/providers/microsoft.insights/datacollectionruleassociations/$associationName`?api-version=2021-09-01-preview"
  $body = @{
    properties = @{
      dataCollectionRuleId = $DCRId
    }
  } | ConvertTo-Json
    Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method PUT -Body $body
}

function Remove-MonitoredObjectsDCRAssociation($TenantID, $associationName) {

    if (-not $TenantId) {
        throw "TenantID is required"
    }
    if (-not $associationName) {
        throw "associationName is required"
    }
    $auth = Get-AzAccessToken -AsSecureString
    $AuthenticationHeader = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer " + $(ConvertFrom-SecureString $auth.Token -AsPlainText)
    }


  $requestURL = "https://management.azure.com/providers/Microsoft.Insights/monitoredObjects/$TenantID/providers/microsoft.insights/datacollectionruleassociations/$associationName`?api-version=2021-09-01-preview"
  Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method DELETE
}


function List-MonitoredObjectsDCRAssociations($TenantID) {

    if (-not $TenantID) {
        throw "TenantID is required"
    }
    $auth = Get-AzAccessToken -AsSecureString
    $AuthenticationHeader = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer " + $(ConvertFrom-SecureString $auth.Token -AsPlainText)
    }

  $requestURL = "https://management.azure.com/providers/Microsoft.Insights/monitoredObjects/$TenantID/providers/microsoft.insights/datacollectionruleassociations`?api-version=2021-09-01-preview"
  (Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method get).value
}

Write-host "Help:"
Write-host "  Assign-MonitoredObjectsContributorRole(UserObjectID) - Assign 'Monitored Objects Contributor' role to a user"
Write-host "  Unassign-MonitoredObjectsContributorRole(UserObjectID) - Remove 'Monitored Objects Contributor' role from a user"
Write-host "  List-MonitoredObjectsRoleAssignments - List all role assignments for 'Monitored Objects Contributor'"
Write-host "  List-MonitoredObjects - List Monitored Objects for a given TenantID"     
Write-host "  Create-MonitoredObjects(TenantId) - Create a Monitored Object for a given TenantID"
Write-host "  Remove-MonitoredObjects(TenantId) - Remove a Monitored Object for a given TenantID"
Write-host "  Add-MonitoredObjectsDCRAssociation(TenantID, associationName, DCRId) - Add a Data Collection Rule Association to a Monitored Object"
Write-host "  Remove-MonitoredObjectsDCRAssociation(TenantID, associationName) - Remove a Data Collection Rule Association from a Monitored Object"
Write-host "  List-MonitoredObjectsDCRAssociations(TenantID) - List Data Collection Rule Associations for a Monitored Object"

Write-host ""

Write-host "Functions loaded." -ForegroundColor Green

