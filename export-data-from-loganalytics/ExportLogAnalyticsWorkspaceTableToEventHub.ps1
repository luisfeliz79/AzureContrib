#####################################################
#
#       Pre-Requisites
#
##################################################### 

# Install this modules

    # Install-module Az -Confirm:$false -Force -Scope CurrentUser
    # Install-module Invoke-AzOperationalInsightsQueryExport -Confirm:$false -Force -Scope CurrentUser 

# For customer with Internet Proxies

[system.net.webrequest]::defaultwebproxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials


# Login and set the subscription

    # Connect-AzAccount -Tenant xxxx.onmicrosoft.com -Subscription "subscription-name"


#####################################################
#
#       Update with your settings
#
##################################################### 


####  SOURCE DATA SETTINGS ####
# The name of the Table in log analytics to export
$TableName= "StorageBlobLogs"

# The workspace Id of the Log Analytics workspace to export from
$WorkspaceId = "17xxxxcb-xxxx-xxxx-xxxx-597fcxxxxxaf"

# By default, the Begin date is automatically calculated based on the retention days.
# to specify a particular begin date, define it like this:   $EndDate = [DateTime]"01/01/2022"
$RetentionPeriodInDays = 30
$BeginDate = (Get-date).AddDays($RetentionPeriodInDays * -1)

# By default, the current time/date is used as the enddate
# to specify a particular end date, define it like this:   $EndDate = [DateTime]"01/01/2022"
$EndDate  = Get-Date          

# Gets data in chunks of XX seconds
# For cases where there are more than 30,000 records in the current interval
# consider lowering this to 60 seconds or less
# Each chunk equals one file
$IntervalInSeconds  = 300       


####  DESTINATION SETTINGS ####

$Destination="EventHub" # Options: File, EventHub

# If the destination is File, specify the folder to save the files
$DestinationFolder = "."

# If the destination is EventHub, specify the EventHub settings
$EventHubNameSpace  = "namespace-name"
$EventHubName       = "hub-name"
$EventHubPolicyName = "the name of the policy"
$EventHubKey        = "the primary or secondary key on the policy"

#####################################################
#
#       Send to EventHub function
#
##################################################### 
function Send-ToEventHub ($Records) {

    $URI = "{0}.servicebus.windows.net/{1}" -f @($EventHubNameSpace,$EventHubName)
    $encodedURI = [System.Web.HttpUtility]::UrlEncode($URI)

    # Calculate expiry value one hour ahead
    $expiry = [string](([DateTimeOffset]::Now.ToUnixTimeSeconds())+3600)

    # Create the signature
    $stringToSign = [System.Web.HttpUtility]::UrlEncode($URI) + "`n" + $expiry

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($EventHubKey)

    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($stringToSign))
    $signature = [System.Web.HttpUtility]::UrlEncode([Convert]::ToBase64String($signature))

    # Create Payload objects
    # Max size is 1MB so we will devide the records in batch of $batchsize
    $BatchSize=400
    
    $PayloadObjects = @()
    $RecBatch = @()
    $Records | ForEach-Object {
        $recBatch += $_
        $recCounter++
        
        if ($recCounter -eq $BatchSize) {
            $PayloadObjects += [PsCustomObject]@{ "Records" = $recBatch } | ConvertTo-Json
            $recBatch = @()
            $recCounter = 0
        }
    }

    Write-host ""

    # Now lets loop through all the batches
    $PayloadObjects | ForEach-Object {

            Write-host "." -NoNewline
            $body = $_

            

            # API headers
            #
            $headers = @{
                "Authorization"="SharedAccessSignature sr=" + $encodedURI + "&sig=" + $signature + "&se=" + $expiry + "&skn=" + $EventHubPolicyName;
                "Content-Type"="application/atom+xml;type=entry;charset=utf-8"; # must be this
                }
            
            # execute the Azure REST API
            $method = "POST"
            $dest = 'https://' +$URI  +'/messages?timeout=60&api-version=2014-01'

            <# used for turning off certificate checking in case you are using fiddler or other man in the middle#>
            <#
            add-type -TypeDefinition  @"
                using System.Net;
                using System.Security.Cryptography.X509Certificates;
                public class TrustAllCertsPolicy : ICertificatePolicy {
                    public bool CheckValidationResult(
                        ServicePoint srvPoint, X509Certificate certificate,
                        WebRequest request, int certificateProblem) {
                        return true;
                    }
                }
            "@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            #>
            
            $getResult=Invoke-RestMethod -Uri $dest -Method $method -Headers $headers -Body $body -SkipHeaderValidation
    }

}


#####################################################
#
#       MAIN
#
##################################################### 

# Script variables - recommended to not modify

$RecordsLimiter     = "30000"  # Keep this at 30000 to prevent "dataset too big" issues

$debug = $False

$checkFile = "ExportLog_LastRunDate.xml"

$Error.clear()

# Load the System.Web assembly to enable UrlEncode
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null


# This line automatically calculates the start date based on the retention days.
$nextDate = $BeginDate

if ((Test-Path $checkFile) -eq $true) {
    
        $nextDate = Import-Clixml -Path $checkFile     
        Write-Host "$(Get-Date) Last run date found, starting from $nextDate"
}

$NumberOfOps=[math]::Round(($endDate - $nextDate).totalSeconds / $IntervalInseconds)

# Start Pulling the data   
Write-host "$(Get-Date) START: Processing $($timeStamps.count) range(s)"
Write-host "$(Get-Date) Begin Date: $BeginDate    End Date: $EndDate"
$counter=1
while ($nextDate -le $endDate) {

    $startDate = $nextDate
    $nextDate  = $nextDate.AddSeconds($IntervalInSeconds)

    $Operation=[PsCustomObject]@{
        StartDate  =  $startDate.ToString("yyyy-MM-ddTHH:mm:ss") 
        EndDate    =  $nextDate.ToString("yyyy-MM-ddTHH:mm:ss")
        fileName   =  "{0}_ExportLog_{1}_to_{2}.json" -f  $TableName, $($startDate -replace '/|:| ','_'),$($nextDate -replace '/|:| ','_')
        StartDateDateTime = $startDate
    }




    # Do some time measurements
    $startOpTime=Get-Date

    #Build the Query
    $timeSelectorKQL = 'where TimeGenerated >= make_datetime("{0}") and TimeGenerated <= make_datetime("{1}")' -f $Operation.startDate,$Operation.EndDate
    $Query = "$TableName |  $TimeSelectorKQL | take $RecordsLimiter " 

    if ($debug) {$query}
    
    try {

        # Note down the last date we tried to work on, in case we get interrupted
        $Operation.StartDateDateTime | Export-Clixml -Path $checkFile 

        # Make the API Call
        $results=Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $Query -ErrorAction stop

        # If there was no error, pull the next date range and write it
        if ($results.error -eq $null) {

                $OutputFileName= $Operation.fileName

                Write-Host "$(Get-Date) [$counter out of $($NumberOfOps)] Saving events from $($Operation.StartDate) $OutputFileName ..." -NoNewline

                
                if ($Destination -eq "File") {

                    $OutputFileName = Join-Path $DestinationFolder $OutputFileName
                    $results.Results | ConvertTo-Json -Depth 99 | out-file -FilePath $OutputFileName

                } elseif ($Destination -eq "EventHub") {

                    Send-ToEventHub -Records $results.Results

                } else {

                    Write-Error "Destination must be File or EventHub"
                    break

                }

                $results.Results | ConvertTo-Json -Depth 99 | out-file -FilePath $OutputFileName



                Write-Host "$($results.results.timegenerated.count) record(s)"

                if ($results.results.timegenerated.count -ge $RecordsLimiter) {

                    Write-Warning "The last range returned $RecordsLimiter events which is the max, but there may be more."
                    Write-Warning 'If you see this warning often, consider changing $IntervalInSeconds to a lesser value'

                    # If there was an warning, lets document it
    
                    $WarningFileName =  "ExportLog_WARNING.txt" 

                    "============== WARNING ===================="                   | Out-file $WarningFileName -Append 
                    "Query: $Query"                                                 | Out-file $WarningFileName -Append 
                    "Time: $(Get-Date)"                                             | Out-file $WarningFileName -Append 
                    "WarningMessage: The last range returned $RecordsLimiter events which is the max, but there may be more." | Out-file $WarningFileName -Append 
    
                    

                    break

                
                } 

            # Else document the error
            } else {

            # If there was an error, lets document it
    
            $ErrorFileName =  "ExportLog_ERROR.txt" 

            "============== REQUEST ERROR ===================="             | Out-file $ErrorFileName -Append 
            "Query: $Query"                                                 | Out-file $ErrorFileName -Append 
            "Time: $(Get-Date)"                                             | Out-file $ErrorFileName -Append 
            "ErrorMessage: $($results.error | ConvertTo-Json -Depth 99)"    | Out-file $ErrorFileName -Append 
    
            Write-host "$(Get-Date) Request Error, see ExportLog_ERROR.txt"

            }
        
    } catch {

            # If there was an error, lets document it
    
            $ErrorFileName =  "ExportLog_ERROR.txt" 

            "============== API ERROR ===================="                 | Out-file $ErrorFileName -Append 
            "Query: $Query"                                                 | Out-file $ErrorFileName -Append 
            "Time: $(Get-Date)"                                             | Out-file $ErrorFileName -Append 
            "ErrorMessage: $Error[0]"                                       | Out-file $ErrorFileName -Append 
    
            Write-host "$(Get-Date) API Error, see ExportLog_ERROR.txt / $Error[0]"

            break

    }

    $counter++

    # Time measurement
    $endOpTime=Get-Date

    #if ($counter -eq 3) {write-host "test stop at 3";break}

    $OpTime        = $endOpTime-$startOpTime
    $OpTimeLeft    = $OpTime.totalSeconds * ($NumberOfOps - $Counter) / 60

    Write-host "Time: $($OpTime.TotalSeconds.tostring('####.00')) second(s) |  Projected time left: $($OpTimeLeft.tostring('##################')) minutes" -ForegroundColor Cyan
}


Write-host "$(Get-Date) END: Completed"

