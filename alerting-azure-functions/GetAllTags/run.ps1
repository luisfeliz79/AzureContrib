
param($Timer)


# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()


# Write an information log with the current time.
Write-Information "Starting scan at: $currentUTCtime"


# Gets an access token using a System assigned or User assigned managed identity
# for App service based workloads only
# If using a user assigned managed identity, configure a setting in app service
# called MSI_CLIENT_ID with the CLIENT ID of the UAMI
function Get-AppServiceMSIToken
{
    param
    (
        $Resource
    )

    Write-Information "Entering Get-AppServiceMSIToken"
    $msiEndpoint = $ENV:IDENTITY_ENDPOINT
    $MSIHeader   = $ENV:IDENTITY_HEADER
    $AppId       = $ENV:MSI_CLIENT_ID
    $apiVersion  = '2019-08-01'

    Write-Information "Fetching new MSI Token"
    $header = @{
        'X-IDENTITY-HEADER' = $MSIHeader
    }

    $uri = '{0}?resource={1}&api-version={2}' -f $msiEndpoint, $resource, $apiVersion

    if ($AppId.length -gt 0) {
        $uri = '{0}&client_id={1}' -f $uri, $AppId 
    }

    $resultObject = Invoke-RestMethod -Method Get -Uri $uri -Headers $header

    $access_token = $resultObject.access_token

    if ($access_token.length -gt 0) {
        Write-Information "Successfully obtained an access token" 
        return $access_token
    } else {
        Write-Information "Problem obtaining Managed Identity based access token"
        return $resultObject
    }
    Write-Information "Exiting Get-AppServiceMSIToken"
    
}


function InvokeResourceExplorerQueryRequest ($KQL,$AccessToken) {
    # Runs a KQL Query against Azure Resource Graph

    $headers=@{
        "Content-Type"  = 'application/json'        
        "Authorization" = "Bearer $($AccessToken)"
    }

    $Payload=@{
        "Query"=$KQL
    } | ConvertTo-Json

    $Url="https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"

    $Results=Invoke-RestMethod -Method POST -UseBasicParsing -Uri $Url -Headers $headers -Body $Payload -ContentType 'application/json' 

    return $Results
}

Write-Information "Performing checks ..."

$msiEndpoint = $ENV:IDENTITY_ENDPOINT
$MSIHeader   = $ENV:IDENTITY_HEADER

if (($null -eq $msiEndpoint -or $null -eq $MSIHeader) -or ("" -eq $msiEndpoint -or "" -eq $MSIHeader)) {
    Write-Information "ERROR: The Managed Identity is not configured. Please enable Managed Identities."
    break
}

$AppId       = $ENV:MSI_CLIENT_ID

if ($null -eq $AppId) {
    Write-Information "Using System Assigned Identity"
} else {
    Write-Information "Using User Assigned Identity with AppId: $AppId"
}


Write-Information "Getting Access token ..."
$AccessToken = Get-AppServiceMSIToken -Resource "https://management.azure.com/"


$kqlQuery=@'
resources
| where type == "microsoft.dbforpostgresql/flexibleservers" 
| where isnotnull(tags)
| project ['id'],['tags']
'@

Write-Information "Running Query ..."
$tags=InvokeResourceExplorerQueryRequest -KQL $kqlQuery -AccessToken $AccessToken

Write-Information "Caching Tags to file ..."
$tags.data | ConvertTo-Json -Depth 99 | Out-File -FilePath "/home/site/wwwroot/cache.json"


