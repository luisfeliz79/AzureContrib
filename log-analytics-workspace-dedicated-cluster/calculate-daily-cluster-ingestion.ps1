
##################################
#   Program Variables            #
##################################

$TenantId = "common"

[System.Net.WebRequest]::DefaultWebProxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials

##################################
#   Support Functions            #
##################################


Function Authenticate($Resource="https://management.azure.com/",$RefreshToken) {
#https://management.core.windows.net/
# Authentication routine which
# handles a variety of scenarios

    $createAuthorizationHeaderSb = {
        if ($null -eq $This.AccessToken) {
            Write-Host "You must authenticate first" -ForegroundColor red;break
        }
        if ($This.IsValid() -eq $false){
            $This.RequestNewToken()
        }
        return "Bearer $($This.AccessToken)"
    }
    $isValidSb = {
        return ((Get-Date).AddMinutes(5) -lt $This.Expiration)
    }

    $refreshTokenSb={
        Write-warning "Refreshing Token..."
        $TokenRequestParams = @{
            Method = 'POST'
            Uri    = "https://login.microsoftonline.com/$TenantId/oauth2/token"
            Body   = @{
                grant_type    = "refresh_token"
                refresh_token = $This.RefreshToken
                client_id     = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
                scope         = [System.Web.HttpUtility]::UrlDecode($This.Scope+'.default')
                #scope         = "https%3A%2F%2Fmanagement.azure.com%2F.default"
            }
        }
        $TokenRequest = Invoke-RestMethod @TokenRequestParams
        $This.AccessToken = $TokenRequest.access_token
        $This.Expiration = (Get-Date).Addseconds($TokenRequest.expires_in)
    }

    
    if ($RefreshToken) {
        # An RT has been passed, use this instead instead of DeviceCodeAuth
        Write-Warning "Using Refresh token"
        $authResult = GetAccessTokenViaRefreshToken -RefreshToken $RefreshToken -Resource $Resource
    } else {
        # Use Device code auth to Authenticate the user
        Write-Warning "Using Devicde code"
        $authResult = GetAccessTokenViaDeviceCode -tenantid $TenantId -resourceid $Resource        
    }
    
    
    $authResultObject=$authResult|convertfrom-json
    $JWTinfo=[System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($($tmpToken=(($authResultObject).access_token -split "\.")[1]; while ($tmpToken.Length % 4) { $tmpToken += "=" };$tmpToken))) | ConvertFrom-Json
    if ($null -ne $JWTinfo.unique_name) {
        
        $AppUser = "$($JwtInfo.unique_name)"
        Write-Host "Logged in as " -NoNewline
        Write-host "$AppUser" -ForegroundColor Green

        $PsObject=[PSCustomObject]@{
            AppUser      = $AppUser
            AccessToken  = ($authResultObject).access_token
            RefreshToken = ($authResultObject).refresh_token
            ObjectId     = $JWTinfo.oid
            Expiration   = (Get-Date).Addseconds($authResultObject.expires_in)
            Scope        =  $Resource           
        }
        $PsObject | Add-Member -Type ScriptMethod -Name CreateAuthorizationHeader  -Value $createAuthorizationHeaderSb 
        $PsObject | Add-Member -Type ScriptMethod -Name IsValid -Value $isValidSb
        $PsObject | Add-Member -Type ScriptMethod -Name RequestNewToken -Value $refreshTokenSb
 
        
        return $PsObject

    } else {
        Write-Error "There was wan error getting an access token, please try again."
        break
    }

}
function GetAccessTokenViaRefreshToken($Resource,$RefreshToken) {
    Write-warning "Getting Token for $Resource ..."
    $TokenRequestParams = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        Body   = @{
            grant_type    = "refresh_token"
            refresh_token = $RefreshToken
            resource      = [System.Web.HttpUtility]::UrlDecode($Resource)
            client_id     = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
            #scope         = [System.Web.HttpUtility]::UrlDecode($Resource)            
        }
    }
    Try {
        $TokenRequest = Invoke-RestMethod @TokenRequestParams
        
        return $TokenRequest | ConvertTo-Json
    } catch {
        write-warning $_ | ConvertTo-Json
            
    }
}
function GetAccessTokenViaDeviceCode {
    [CmdletBinding()]
    param
    (
        # The tenant ID of the tenant to collect the OAUTH token from
        [Parameter(Mandatory = $true)]
        [System.String]
        $tenantid,

        # The resource ID of resource you want an OAUTH token for
        [Parameter(Mandatory = $true)]
        [System.String]
        $resourceid
    )
    # Known Client ID for PowerShell
    $clientid = '04b07795-8ddb-461a-bbee-02f9e1bf7b46'

    # Request device login @ Microsoft
    $DeviceCodeRequestParams = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$TenantID/oauth2/devicecode"
        Body   = @{
            client_id = $ClientId
            resource  = $ResourceID
        }
    }
    $DeviceCodeRequest = Invoke-RestMethod @DeviceCodeRequestParams

    # Show the user a message where he/she should login
    Write-Host $DeviceCodeRequest.message -ForegroundColor Yellow

    # Poll the token site to see or the user succesfully autorized
    do {
        try {
            $TokenRequestParams = @{
                Method = 'POST'
                Uri    = "https://login.microsoftonline.com/common/oauth2/token"
                Body   = @{
                    grant_type = "urn:ietf:params:oauth:grant-type:device_code"
                    code       = $DeviceCodeRequest.device_code
                    client_id  = $ClientId
                }
            }
            $TokenRequest = Invoke-RestMethod @TokenRequestParams
            # Add a new line to the ouput, so it lookks better
            write-host ""
            # Return the token information
            return $TokenRequest | ConvertTo-Json
        }
        catch {
            if ((convertfrom-json $_.ErrorDetails.Message).error -eq "authorization_pending") {
                write-host "." -NoNewline
                Start-Sleep -Seconds 5
            }
            else {
                throw "Unkown error while requesting token"
            }
        }
    } while ($true)

}

Function GetLogAnalyticsUsage ($lawId) {
      

    $headers=@{
        "x-ms-version"  = '2014-10-01'        
        "Authorization" = $Global:LawAPIAuth.CreateAuthorizationHeader()
    }
                
    $Query=[PsCustomObject]@{
        query=@'
    Usage
    | where TimeGenerated > startofday(ago(31d))
    | where StartTime > startofday(ago(31d))
    | where IsBillable == true
    | summarize TotalVolumeGB = sum(Quantity) / 1000 by bin(StartTime, 1d), Solution
'@    
        workspaces=@($lawId)
    } | convertTo-Json

        Write-Host "$lawId"
        # Get Details about the Web App Resource ID
        $Url="https://api.loganalytics.io/v1/workspaces/{0}/query" -f $lawId
            try {
                $results = Invoke-RestMethod -Method POST -UseBasicParsing -Uri $Url -Headers $headers -ContentType 'application/json' -Body $Query -ErrorAction SilentlyContinue
                return $results
            } catch {Write-Host "    Invalid Resource: $ResourceId - $_" -ForegroundColor Red;break}
    
    
} 

Function GetLogAnalyticsClusterLinkedWorkspaces ($ClusterId) {

$query = @"
    resources
    | where type == "microsoft.operationalisnights/clusters"
    | where id =~ '$ClusterId'
"@
    try {
        $Response = InvokeResourceExplorerQuery -KQL $query

        $Response.data.properties.associatedWorkspaces | ForEach-Object {
            [PSCustomObject]@{
                lawId              = $_.workspaceId
                name               = $_.workspaceName
                id                 = $_.resourceId
                clusterId          = $Response.data.id
                clusterLawId       = $Response.data.properties.clusterId
                clusterName        = $Response.data.name
                clusterLocation    = $Response.data.location
                clusterRG          = $Response.data.resourcegroup
                clusterSKU         = $Response.data.sku
                clusterBillingType = $Response.data.properties.billingType
            }
        }

    } catch {
        Write-host $_ | ConvertTo-Json
    }
}
Function GetLogAnalyticsClusterLinkedWorkspacesDev ($ClusterId) {

    $query = @"
        resources
        | where type =~ 'microsoft.operationalinsights/workspaces'
"@
        try {
            $Response = InvokeResourceExplorerQuery -KQL $query
            
            $Response.data | ForEach-Object {
                [PSCustomObject]@{
                    lawId              = $_.properties.customerId
                    name               = $_.name
                    id                 = $_.id                    
                }
            }
    
        } catch {
            Write-host $_ | ConvertTo-Json
        }
}

function InvokeResourceExplorerQuery ($KQL) {
    # Runs a KQL Query against Azure Resource Graph

    $headers=@{
        "Content-Type"  = 'application/json'        
        "Authorization" = $Global:Auth.CreateAuthorizationHeader()
    }

    $Payload=@{
        "Query"=$KQL
    } | ConvertTo-Json

    $Url="https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"

    $Results=Invoke-RestMethod -Method POST -UseBasicParsing -Uri $Url -Headers $headers -Body $Payload -ContentType 'application/json' 

    return $Results
}

function CrunchData ($ReportData) {
    $Aggregated=$ReportData.tables | ForEach-Object {
        $_.rows | ForEach-Object {
            [PSCustomObject]@{
               lawId=""
               lawName=""
               date      = $_[0]
               logType   = $_[1]
               value     = $_[2]
            }
        }
    }
    
    $Aggregated | Group-Object date | ForEach-Object {
    
        [PSCustomObject]@{
            date      = $_.Name
            count   = $_.Count
            total     = ($_.group | Measure-Object -Sum -Property value).sum
         }
    
    } | Sort-Object date
}

##################################
#   Exported Functions           #
##################################

Function Get-LogAnalyticsClusterReport($ClusterId,[Switch]$ForceAuthentication) {
    
    
    # Authenticate
    if ($Null -ne $Global:Auth -and $Global:Auth.IsValid() -eq $true -and $ForceAuthentication -eq $false) {
        # Do nothing, we have a valid Access token
        #Write-warning "Doing nothing"
    } else {
        #Write-warning "Triggering auth"
        $Global:Auth=Authenticate -UseWebLogin:$UseWebLogin
        $Global:LawAPIAuth=Authenticate -Resource "https://api.loganalytics.io" -RefreshToken ($global:Auth).RefreshToken
    }
  
    # First get a list of LAWs linked to the cluster
    Write-warning "Getting list of Cluster Linked workspaces..."
    $laws=GetLogAnalyticsClusterLinkedWorkspaces -ClusterId $ClusterId
    # Then for every LAW get it's daily usage information



    $ReportData=@()
    Write-warning "Getting Daily usage info ..."
    $laws | ForEach-Object {
        Write-warning " - $($_.name)"
        $ReportData+=GetLogAnalyticsUsage -lawId $_.lawId
    }
    # Crunch the data and present it
    CrunchData -ReportData $ReportData
}




