
# Role assignment - Need GA
function Assign-MonitoredObjectContributorRole($UserObjectID) {
  New-AzRoleAssignment -Scope '/providers/Microsoft.Insights' -RoleDefinitionName 'Monitored Objects Contributor' -ObjectId $UserObjectID
}
# Needs GA
function Unassign-MonitoredObjectContributorRole($UserObjectID) {
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
function Create-MonitoredObject($TenantId, $Location = "eastus2") {

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
function Remove-MonitoredObject($TenantId) {

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
function Add-MonitoredObjectDCRAssociation($TenantID, $associationName, $DCRId) {

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

function Remove-MonitoredObjectDCRAssociation($TenantID, $associationName) {

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
