
##################################
#   Program Variables            #
##################################


# 1) Replace common with your tenant name
     $TenantId = "common"

# 2) To enable the Hub check function, define the Hub VNET Id for each region
    $Global:RegionalHubVnets=@{}  # (do not remove this)

    # Examples:
    $Global:RegionalHubVnets["westus3"]=@("/subscriptions/xxxxxx/resourceGroups/xxxx/providers/Microsoft.Network/virtualNetworks/vnet-hub1-westus3")
    $Global:RegionalHubVnets["eastus"]=@("/subscriptions/xxxxx/resourceGroups/xxxx/providers/Microsoft.Network/virtualNetworks/vnet-hub1-eastus")




##################################
#   Support Functions            #
##################################

$Global:RgLocations=@{}

[System.Net.WebRequest]::DefaultWebProxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials

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

function getResourceGroupLocation ($RG) {

    
          $headers=@{
                    "Content-Type"  = 'application/json'        
                    "Authorization" = $Global:Auth.CreateAuthorizationHeader()
          }
                

          
          
          
                $Url="https://management.azure.com/{0}?api-version=2021-04-01" -f $RG
                try {
                    $Result= Invoke-RestMethod -Method GET -UseBasicParsing -Uri $Url -Headers $headers -ContentType 'application/json' -ErrorAction SilentlyContinue
                    
                    return $result.location

                    
                } catch {
                    write-warning "error $_"
                }




}

function getPrivateDnsZones ([switch]$UseWebLogin,[switch]$ForceAuthentication) {

    # Authenticate
    if ($Null -ne $Global:Auth -and $Global:Auth.IsValid() -eq $true -and $ForceAuthentication -eq $false) {
        # Do nothing, we have a valid Access token
    } else {
        $Global:Auth=Authenticate -UseWebLogin:$UseWebLogin
    } 




$KQL=@"
    resources
    | where type == 'microsoft.network/privatednszones'
"@


    $zones = InvokeResourceExplorerQuery -KQL $KQL

   

    $zones.data | ForEach-Object {
        
        [PSCustomObject]([ordered]@{
        
            name            = $_.name
            ResourceGroup   = $_.resourcegroup
            id              = $_.id
            subscription    = $_.subscriptionId
            location        = $(getResourceGroupLocation -RG $(($_.id -split '/')[0..4] -join '/'))
            numberOfVirtualNetworkLinks = $_.properties.numberOfVirtualNetworkLinks
            numberOfRecordSets =          $_.properties.numberOfRecordSets

        })
    }



}

function getPrivateDnsZonesLinks ($zones) {


    $LinksReport=@()
    $zones | foreach {

          $headers=@{
                    "Content-Type"  = 'application/json'        
                    "Authorization" = $Global:Auth.CreateAuthorizationHeader()
          }
                

          $Resource=$_
          Write-warning " - $(($Resource.id -split '/')[-1])"
          # Get Virtual network link for this zone
                $Url="https://management.azure.com/{0}/virtualNetworkLinks?api-version=2018-09-01" -f $Resource.id
                try {
                    $Result= Invoke-RestMethod -Method GET -UseBasicParsing -Uri $Url -Headers $headers -ContentType 'application/json' -ErrorAction SilentlyContinue
                    #write-warning $($result | ConvertTo-Json)
                    $Result.value | foreach {

                        $currentLink=$_

                        $LinksReport+=[PsCustomObject]@{
                    
                            ZoneName            = $Resource.name
                            ZoneId              = $Resource.id
                            LinkedVNET          = $currentLink.properties.virtualNetwork.id
                            ProvisionState      = $currentLink.properties.provisioningState
                            RegistrationEnabled = $currentLink.properties.registrationEnabled
                            State               = $currentLink.properties.virtualNetworkLinkState
                            ResourceGroup       = $Resource.resourcegroup
                            subscription        = $Resource.subscription
                            location            = $Resource.location

                    
                    
                        }



                    }
                    





                    
                } catch {
                    write-warning "error $_"
                }
                    

    }
    return $LinksReport
}

function CheckMissingHubLinks ($Zone,$ZoneLinks) {

    $Status="OK"
    $CurrentZoneLinks=$ZoneLinks | where ZoneId -eq $Zone.id
    
    $NeededHubZones=$Global:RegionalHubVnets[$Zone.location]
   
    if ($NeededHubZones -eq $null) { $Status = "Region $($Zone.location) not defined in script, cannot check for Hub Links";return $Status}

    $NeededHubZones | ForEach-Object {

        if ($CurrentZoneLinks.LinkedVNET -notcontains $_) { $Status="Missing Hub Link" }

    }

    
    return $Status

}

function CheckLinkState ($Zone,$ZoneLinks) {

    $Status="OK"
    $CurrentZoneLinks=$ZoneLinks | where ZoneId -eq $Zone.id

    $ZoneLinks | ForEach-Object {

        if ($_.ProvisionState -ne 'Succeeded' -or $_.State -ne 'Completed') {$Status="Link Status issue with Linked VNET $($_.LinkedVNET)"}

    }
    
    return $Status

}

Function Authenticate([Switch]$UseWebLogin) {
# Authentication routine which
# handles a variety of scenarios

    $createAuthorizationHeaderSb = {
        if ($This.AccessToken -eq $null) {
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
                scope         = "https%3A%2F%2Fmanagement.azure.com%2F.default"
            }
        }
        $TokenRequest = Invoke-RestMethod @TokenRequestParams
        $This.AccessToken = $TokenRequest.access_token
        $This.Expiration = (Get-Date).Addseconds($TokenRequest.expires_in)
    }

    if ($UseWebLogin) {
        $authResult=WebLogin
    } else {
        $authResult=GetAccessTokenViaDeviceCode -tenantid $TenantId -resourceid "https://management.core.windows.net/"
    }
    
    $authResultObject=$authResult|convertfrom-json
    $JWTinfo=[System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($($tmpToken=(($authResultObject).access_token -split "\.")[1]; while ($tmpToken.Length % 4) { $tmpToken += "=" };$tmpToken))) | ConvertFrom-Json
    if ($JWTinfo.unique_name -ne $null) {
        
        $AppUser = "$($JwtInfo.unique_name)"
        Write-Host "Logged in as " -NoNewline
        Write-host "$AppUser" -ForegroundColor Green

        $PsObject=[PSCustomObject]@{
            AppUser      = $AppUser
            AccessToken  = ($authResultObject).access_token
            RefreshToken = ($authResultObject).refresh_token
            ObjectId     = $JWTinfo.oid
            Expiration   = (Get-Date).Addseconds($authResultObject.expires_in)            
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
Function WebLogin() {
# Process Web based login Flow

    $LoginServerSB={
    param ($TenantId)

        function respond ($Context, $Body) {
            $response=$context.Response
            $responseString = $Body
            $buffer=[System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.ContentLength64=$buffer.Length
            $Output=$response.OutputStream
            $output.Write($buffer,0,$buffer.Length)
        }

        function redirect ($Context, $url) {
        
            Write-Warning "redirecting to $url"
            $response=$context.Response
            $response.RedirectLocation=$url
            $response.Redirect($url)
            $responseString = $url
            $buffer=[System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.ContentLength64=$buffer.Length
            $Output=$response.OutputStream
            $output.Write($buffer,0,$buffer.Length)

        }


        $loginListener = New-Object System.Net.HttpListener
        $loginListener.Prefixes.Add("http://localhost:50144/")
        try {
            Invoke-RestMethod -Uri "http://localhost:50144/" -ErrorAction SilentlyContinue | Out-Null
        } catch {}
        
        $loginListener.Start()
        #write-warning "Login server starts"
        $loginContext = $loginListener.GetContext()
        $loginRequest=$loginContext.Request
            if ($loginRequest.QueryString -contains 'code')
            {
                #respond -Context $loginContext -Body "<HTML><BODY>Login successful, you may now close this browser</BODY></HTML>"
                $bodyObj= @{
                  code = (($loginRequest.RawUrl -split '\?|&')[1] -split '=')[1]
                  client_id = '04b07795-8ddb-461a-bbee-02f9e1bf7b46'
                  grant_type = 'authorization_code'
                  client_info = 1
                  code_verifier='K0xPLY4VuUEQhbHst_G_3kP-rR5i8SZ9X0Wxp4tteHY'
                  redirect_uri='http%3A%2F%2Flocalhost%3A50144'
                  scope='https%3A%2F%2Fmanagement.core.windows.net%2F%2F.default+offline_access+openid+profile'
                }

                $url="https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
                $body="code={0}&client_id={1}&grant_type={2}&client_info=1&code_verifier={3}&redirect_uri={4}&scope={5}" -f $bodyObj.code,$bodyObj.client_id,$bodyObj.grant_type,$bodyObj.code_verifier,$bodyObj.redirect_uri,$bodyObj.scope
                #write-warning $body
                $result=Invoke-RestMethod -Method Post -Uri $url -Body $body -ContentType 'application/x-www-form-urlencoded' | ConvertTo-Json -Depth 99
                respond -Context $loginContext -body "You may now close this browser"

            } else {
                respond -Context $loginContext -Body "<HTML><BODY>There was an error $($request | ConvertTo-Json)</BODY></HTML>"
                $result='error'
            }
        $loginListener.stop()
        #write-warning "Login server ends"
        
        $result   
    }
    $loginJob=Start-Job -Name "SignInReceiver" -ScriptBlock $LoginServerSB -ArgumentList $TenantId

    # Oauth settings for Azure CLI
    $CLIENT_ID="04b07795-8ddb-461a-bbee-02f9e1bf7b46"
    $RESPONSE_URL="http%3A%2F%2Flocalhost%3A50144"
    $SCOPE="https%3A%2F%2Fmanagement.azure.com%2F.default"
    $CODE_CHALLENGE='K0xPLY4VuUEQhbHst_G_3kP-rR5i8SZ9X0Wxp4tteHY'
    $authUrl="https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize?client_id=$CLIENT_ID&response_type=code&redirect_uri=$RESPONSE_URL&scope=$SCOPE+offline_access+openid+profile&state=nLArqHBmcCKMOoYf&code_challenge=$CODE_CHALLENGE&code_challenge_method=plain&nonce=38c160e2a0f91568ef3194ff6b6cb8c2f0d86a5ea71f01f4659ad6fcc36d329a&client_info=1&claims=%7B%22access_token%22%3A+%7B%22xms_cc%22%3A+%7B%22values%22%3A+%5B%22CP1%22%5D%7D%7D%7D&prompt=select_account"
    
    # Launches your browser
    start "$authUrl"

    Write-Warning "Please authenticate in your browser"

    while ($true) {
        # Wait until the user has logged in
        if ((Get-Job -Id $loginJob.Id).State -eq "Completed") {
            
            $AuthResult = Receive-Job -Job $loginJob
            remove-job -Job $loginJob
            return $AuthResult
        
        }                                     
        sleep 1                                    
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


##################################
#   Exported Functions           #
##################################

function Create-PrivateDNSReport () {
    [CmdletBinding()]
    param( 
       [Switch]$UseWebLogin,
       [Switch]$ForceAuthentication
    )


    # Authenticate
    if ($Null -ne $Global:Auth -and $Global:Auth.IsValid() -eq $true -and $ForceAuthentication -eq $false) {
        # Do nothing, we have a valid Access token
    } else {
        $Global:Auth=Authenticate -UseWebLogin:$UseWebLogin
    } 

    $zonesReport = @()

    $zones     = getPrivateDnsZones
    $zoneLinks = getPrivateDnsZonesLinks -zones $zones
    $zoneLinks | Export-Csv -Path "$pwd\PrivateDnsZoneLinksReport.csv" -NoTypeInformation
    Write-Host "Created $pwd\PrivateDnsZoneLinksReport.csv"
    $zonesReport+=$zones | ForEach-Object {

        [PSCustomObject]([ordered]@{
        
                Subscription    = $_.subscription
                ResourceGroup   = $_.resourcegroup
                ZoneName        = $_.name
                Region          = $_.location
                NumberofLinks   = $_.numberOfVirtualNetworkLinks
                NumberOfRecords = $_.numberOfRecordSets
                HubLinkCheck    = CheckMissingHubLinks -Zone $_ -ZoneLinks $zoneLinks
                LinkStatusCheck = CheckLinkState -Zone $_ -ZoneLinks $zoneLinks         
                ZoneId          = $_.id

            })
        }
    
    $zonesReport | Export-Csv -Path "$pwd\PrivateDnsZoneStatusReport.csv" -NoTypeInformation
    Write-Host "Created $pwd\PrivateDnsZoneStatusReport.csv"
}




Write-Host "`nTo use me:`n"
Write-Host "   Dot Source the script:"
Write-Host "       . $PSCommandPath  " -ForegroundColor White
Write-Host "`n   To login and create a report"
Write-host "      Create-PrivateDNSReport" -ForegroundColor White
