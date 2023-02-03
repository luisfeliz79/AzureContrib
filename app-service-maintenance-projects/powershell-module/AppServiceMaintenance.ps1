
##################################
#   Program Variables            #
##################################

$TenantId = "common"

$SupportedPriviledgeRoles=@()
$SupportedPriviledgeRoles+="8e3af657-a8ff-443c-a75c-2fe8c4bcb635" # Owner
$SupportedPriviledgeRoles+="b24988ac-6180-42a0-ab88-20f7382dd24c" # Contributor
$SupportedPriviledgeRoles+="de139f84-1756-47ae-9be6-808fbbe84772" # Website Contributor

[System.Net.WebRequest]::DefaultWebProxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials

##################################
#   Support Functions            #
##################################


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

Function GetAppServiceWebAppsBatch ($ListOfIds) {
# Process a list of ResourceIDs and gets Resource Information
# Assumes Azure App Service Web apps

$List=('"' + $($ListOfIds -join '", "') + '"').ToString()


$KQL=@"
    resources
    | where id in ($List)
"@


    $WebApps = InvokeResourceExplorerQuery -KQL $KQL

    $Webapps.data | ForEach-Object {
        
        [PSCustomObject]([ordered]@{
        
            WebApp         = $_.name
            ResourceGroup  = $_.resourcegroup
            kind           = $_.kind
            location       = $_.location
            AppServicePlan = ($_.properties.serverFarmId -split '/')[-1]
            type           = $_.type
            
            state          = $_.properties.state
        })
    }

}
Function RestartAppServiceWebAppsBatch ($ListOfIds) {
# Process a list of ResourceIDs and restarts
# Assumes Azure App Service Web apps



    $ListOfIds | ForEach-Object {
        $headers=@{
            "Content-Type"  = 'application/json'        
            "Authorization" = $Global:Auth.CreateAuthorizationHeader()
        }

        Write-Warning "Restarting $_"
        $Url="https://management.azure.com{0}/restart?api-version=2022-03-01" -f $_
        
        $results = Invoke-RestMethod -Method POST -UseBasicParsing -Uri $Url -Headers $headers -Body $Payload -ContentType 'application/json'  

        return $results
    }

}

Function CheckRBACUserAccess ($ListOfIds, $UserObjectId) {
# Process a list of ResourceIDs and checks
# if the user has at least one role in list
# $SupportedPriviledgeRoles


        $Filter='$Filter=assignedTo(' + "'{$($UserObjectId)}'" + ')'
        $ListOfIds | ForEach-Object {
            $headers=@{
                "Content-Type"  = 'application/json'        
                "Authorization" = $Global:Auth.CreateAuthorizationHeader()
            }
            #Write-Warning "Checking access $_"
            
            # Get the list of Roles on that Resource for the logged in user
            $Url="https://management.azure.com{0}/providers/Microsoft.Authorization/roleAssignments?api-version=2015-07-01&{1}" -f $_,$Filter
            $results = Invoke-RestMethod -Method GET -UseBasicParsing -Uri $Url -Headers $headers -ContentType 'application/json'  
            
            # Compare to Supported roles
            $ListOfRoles=(($results.value.properties | Group-Object roleDefinitionId).name -split '/')[-1]

            $UserHasAccess=$false
            $ListOfRoles | ForEach-Object {
                if ($SupportedPriviledgeRoles -Contains $_) {
                    $UserHasAccess=$true
                }
            }
            
            return $UserHasAccess
        }
}

Function GetAppServiceWebAppInfo ($ListOfIds) {
# Process a list of ResourceIDs and gets details
# Assumes Azure App Service Web apps



        Write-Host "Validating Resource IDs...."
        $ListOfIds | ForEach-Object {
            $headers=@{
                "Content-Type"  = 'application/json'        
                "Authorization" = $Global:Auth.CreateAuthorizationHeader()
            }
            

            $ResourceId=$_
            Write-Host " - $(($ResourceId -split '/')[-1])"
            # Get Details about the Web App Resource ID
            $Url="https://management.azure.com/{0}?api-version=2022-03-01" -f $ResourceId
            try {
                $results = Invoke-RestMethod -Method GET -UseBasicParsing -Uri $Url -Headers $headers -ContentType 'application/json' -ErrorAction SilentlyContinue
                $Access = CheckRBACUserAccess -ListOfIds @($ResourceId) -UserObjectId $Global:Auth.ObjectId

                $results | ForEach-Object {
            
                    [PSCustomObject]([ordered]@{
                    
                        WebApp         = $_.name
                        ResourceGroup  = $_.properties.resourcegroup
                        kind           = $_.kind
                        location       = $_.location
                        AppServicePlan = ($_.properties.serverFarmId -split '/')[-1]
                        type           = $_.type
                        #tags           = $_.tags | ConvertTo-Json
                        state          = $_.properties.state
                        Access         = $Access
                        id             = $_.id
                    })
                } 
            } catch {Write-Host "    Invalid Resource: $ResourceId - $_" -ForegroundColor Red;break}

        } # list loop
}
Function ConfirmAndReboot{
[CmdletBinding(SupportsShouldProcess)]    
param ($ListOfIds)
# Wrapper function to confirm restarts


    if ($PSCmdlet.ShouldProcess('The list of APPS above','Reboot')){
        RestartAppServiceWebAppsBatch -ListOfIds $ListOfIds
    }

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

        function respond ($Context, $Body) {
            $response=$context.Response
            $responseString = $Body
            $buffer=[System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.ContentLength64=$buffer.Length
            $Output=$response.OutputStream
            $output.Write($buffer,0,$buffer.Length)
        }

        function redirect ($Context, $url) {
        
            #Write-Warning "redirecting to $url"
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

                $url='https://login.microsoftonline.com/organizations/oauth2/v2.0/token'
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
    $loginJob=Start-Job -Name "SignInReceiver" -ScriptBlock $LoginServerSB

    # Oauth settings for Azure CLI
    $CLIENT_ID="04b07795-8ddb-461a-bbee-02f9e1bf7b46"
    $RESPONSE_URL="http%3A%2F%2Flocalhost%3A50144"
    $SCOPE="https%3A%2F%2Fmanagement.azure.com%2F.default"
    $CODE_CHALLENGE='K0xPLY4VuUEQhbHst_G_3kP-rR5i8SZ9X0Wxp4tteHY'
    $authUrl="https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize?client_id=$CLIENT_ID&response_type=code&redirect_uri=$RESPONSE_URL&scope=$SCOPE+offline_access+openid+profile&state=nLArqHBmcCKMOoYf&code_challenge=$CODE_CHALLENGE&code_challenge_method=plain&nonce=38c160e2a0f91568ef3194ff6b6cb8c2f0d86a5ea71f01f4659ad6fcc36d329a&client_info=1&claims=%7B%22access_token%22%3A+%7B%22xms_cc%22%3A+%7B%22values%22%3A+%5B%22CP1%22%5D%7D%7D%7D&prompt=select_account"
    
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

function Restart-WebApps () {
    [CmdletBinding()]
    param( 
       [Parameter(Mandatory = $true)]                   
       [String]$Path,
       [Switch]$UseWebLogin,
       [Switch]$ForceAuthentication

    )

    

    if ((Test-Path -Path $Path) -ne $true) {
        Write-host "Could not find file $Path"
        break
    }
    
    # Read the file contain App Service Resource IDs
    $ListOfIds=Get-Content -path $Path


    # Authenticate
    if ($Null -ne $Global:Auth -and $Global:Auth.IsValid() -eq $true -and $ForceAuthentication -eq $false) {
        # Do nothing, we have a valid Access token
    } else {
        $Global:Auth=Authenticate -UseWebLogin:$UseWebLogin
    } 

    # Get App List status
    $AppStatusResult=GetAppServiceWebAppInfo -ListOfIds $ListOfIds
    if ($AppStatusResult -ne $null) {

        $AppStatusResult | Format-Table Access,WebApp,ResourceGroup,kind,location,AppServicePlan,type,state
        
        if ($AppStatusResult.Access -contains $false) {
            Write-Warning "You may not have access to Restart some of the apps. Do you need to elevate via PIM?"
            Write-Warning "You may not have access to Restart some of the apps. Do you need to elevate via PIM?"
            Write-Warning "You may not have access to Restart some of the apps. Do you need to elevate via PIM?"
        }

        Write-Host "`nATTENTION: ALL OF THE APPS LISTED ABOVE are ABOUT to be REBOOTED!" -ForegroundColor Red
        
        # Restart After confirmation
        ConfirmAndReboot -ListOfIds $AppStatusResult.id -Confirm

        # # Show status until all are in running state
        # while ($True) {
        #     $AppStatusResult=GetAppServiceWebAppsBatch -ListOfIds $AppStatusResult.id
        #     $AppStatusResult | ft
        #     if ($AppStatusResult.state -ne 'Stopped') {break}
        #     sleep 5
        # }
    } else {
        Write-Warning "No apps returned. Check input file."    
    }

}



Write-Host "To use me:"
Write-host "   Restart-WebApps -Path filename.txt"



