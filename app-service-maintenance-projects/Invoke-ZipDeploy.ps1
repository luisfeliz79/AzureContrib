function UnwrapSecureString() {
    param (
        [Parameter(Mandatory = $true)]
        $SecureString
    )

    $incomingType = $SecureString.GetType().Name
    if ($incomingType -eq "String") {
        return $SecureString
    } else {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }

}

# Write a powershell function that uses Invoke-RestMethod to ZipDeploy a zip file to Azure Functions

function Invoke-ZipDeploy {
    param (
        [string]$Name,
        [string]$ArchivePath,
        [switch]$FollowLog,
        [string]$Proxy
    )

    $url = "https://$Name.scm.azurewebsites.net/api/zipdeploy?isAsync=true&Deployer=az_cli_functions"

    Write-Host "Obtaining access token..."
    $accessToken = UnwrapSecureString -SecureString (Get-AzAccessToken).Token

    Write-Host "Deploying $ArchivePath to $Name ..."


    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Accept-Encoding" = "gzip, deflate"
    }

    #$body = Get-Content -Path $ArchivePath # -Raw

    try {
       # $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "application/zip" -Verbose
        if ($Proxy) {
            $response = Invoke-WebRequest -Uri $url -Method Post -Headers $headers  -ContentType "application/octet-stream" -proxy $Proxy -infile $ArchivePath
        } else {
            $response = Invoke-WebRequest -Uri $url -Method Post -Headers $headers  -ContentType "application/octet-stream" -infile $ArchivePath
        }


        Write-Host "[$($response.StatusCode)] $Url"
        $DepId = $response.headers.'SCM-DEPLOYMENT-ID'
        $logUrl = "https://$Name.scm.azurewebsites.net/api/deployments/$DepId/log"
        Write-Host ""
        Write-Host "Deployment log can be viewed at: $logUrl"

        if ($FollowLog) {
            while ($true) {
                Start-Sleep -Seconds 5
                $logResponse = Invoke-RestMethod -Uri $logUrl -Method Get -Headers $headers -ErrorAction SilentlyContinue
                $logResponse | ForEach-Object { 
                    if ($_.message -ne $null) {
                        Write-warning "MESSAGE: $($_.message)"
                        if ($_.message -match "Deployment successful") {
                            write-warning "COMPLETE"
                            break
                        }
                    }
                    if ($_.details_url -ne $null) {
                        Write-warning "DETAILS: $($_.details_url)"
                        
                        $Content=(Invoke-RestMethod -Uri $_.details_url -Method Get -Headers $headers)
                        $Content | ForEach-Object {
                            if ($_.message -ne $null) {
                                Write-warning "  DETAIL MESSAGE: $($_.message)"
                            }
                        }

                    }
                }
            }
        }
        
        
    } catch {
        Write-Warning "Failed to deploy zip file: $_"
    }
}

Write-Host "To use this script:"
Write-host "* Source this file, Example:"
Write-host "      . .\Invoke-ZipDeploy.ps1"
Write-host "* Call the function, Example:"
Write-host "      Invoke-ZipDeploy -Name <FunctionAppName> -ArchivePath <PathToZipFile>"