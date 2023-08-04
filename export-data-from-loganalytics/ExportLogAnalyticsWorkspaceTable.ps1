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

# The name of the Table in log analytics to export
$TableName= "AppTraces"

# The workspace Id of the Log Analytics workspace to export from
$WorkspaceId = "17xxxxcb-xxxx-xxxx-xxxx-597fcxxxxxaf"
   

# By default, the Begin date is automatically calculated based on the retention days.
# to specify a particular begin date, define it like this:   $EndDate = [DateTime]"01/01/2022"
$RetentionPeriodInDays = 30
$BeginDate = (Get-date).AddDays($RetentionPeriodInDays * -1)

# By default, the current time/date is used as the enddate
# to specify a particular end date, define it like this:   $EndDate = [DateTime]"01/01/2022"
$EndDate  = Get-Date          


# Gets data in chunks of XX minutes
# For cases where there are more than 30,000 records in the current interval
# consider lowering this to 30 minutes or 15 minutes
# Each chunk equals one file
$IntervalInMinutes  = 60       



#####################################################
#
#       START
#
##################################################### 

# Script variables - recommended to not modify

$RecordsLimiter     = "30000"  # Keep this at 30000 to prevent "dataset too big" issues

$debug = $False


# Create the list of ranges that need to be pulled
$timeStamps=@()


# This line automatically calculates the start date based on the retention days.
$nextDate = $BeginDate




   
while ($nextDate -le $endDate) {

    $startDate = $nextDate
    $nextDate  = $nextDate.AddMinutes($IntervalInMinutes)

    $timeStamps+=[PsCustomObject]@{
        
        StartDate  =  $startDate.ToString("yyyy-MM-ddTHH:mm:ss") 
        EndDate    =  $nextDate.ToString("yyyy-MM-ddTHH:mm:ss")
        fileName   =  "{0}_ExportLog_{1}_to_{2}.json" -f  $TableName, $($startDate -replace '/|:| ','_'),$($nextDate -replace '/|:| ','_')
        
    }

}

# Start Pulling the data   
Write-host "$(Get-Date) START: Processing $($timeStamps.count) range(s)"
Write-host "$(Get-Date) Begin Date: $BeginDate    End Date: $EndDate"

$counter=1
$timeStamps | ForEach-Object {

  #Build the Query
  $timeSelectorKQL = 'where TimeGenerated >= make_datetime("{0}") and TimeGenerated <= make_datetime("{1}")' -f $_.startDate,$_.EndDate
  $Query = "$TableName |  $TimeSelectorKQL | take $RecordsLimiter " 

  if ($debug) {$query}
 
  try {

       # Make the API Call
       $results=Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $Query -ErrorAction stop

       # If there was no error, pull the next date range and write it
       if ($results.error -eq $null) {

            Write-Host "$(Get-Date) [$counter out of $($timeStamps.count)] Saving events from $($_.StartDate) $OutputFileName ..." -NoNewline

            $OutputFileName= $_.fileName

            $results.Results | ConvertTo-Json -Depth 99 | out-file -FilePath $OutputFileName

            Write-Host "$($results.results.timegenerated.count) record(s)"

            if ($results.results.timegenerated.count -ge $RecordsLimiter) {

                Write-Warning "The last range returned $RecordsLimiter events which is the max, but there may be more."
                Write-Warning 'If you see this warning often, consider changing $IntervalInMinutes to a lesser value'

                   # If there was an warning, lets document it
   
                   $WarningFileName =  "ExportLog_WARNING.txt" 

                   "============== WARNING ===================="                  | Out-file $WarningFileName -Append 
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

  #if ($counter -eq 3) {write-host "test stop at 3";break}

}


Write-host "$(Get-Date) END: Completed"







