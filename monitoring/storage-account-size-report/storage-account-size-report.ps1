function InvokeResourceExplorerQuery ($KQL) {
    # Runs a KQL Query against Azure Resource Graph

    $headers=@{
        "Content-Type"  = 'application/json'
        "Authorization" = "Bearer $GlobalToken"
    }

    $Payload=@{
        "Query"=$KQL
    } | ConvertTo-Json

    $Url="https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"

    $InvokeARGResults=Invoke-RestMethod -Method POST -UseBasicParsing -Uri $Url -Headers $headers -Body $Payload -ContentType 'application/json'

    return $InvokeARGResults
}
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

function GetStorageAccountBySubAndLocation {

$FilteredKQL=@"
    resources
    | where type == 'microsoft.storage/storageaccounts'
"@

$GetSAResults=InvokeResourceExplorerQuery -KQL $FilteredKQL

$StorageAccounts=$GetSAResults.data | foreach {
    [PsCustomObject]@{
        Id                 = $_.id
        StorageAccountName = $_.name
        ResourceGroup      = $_.resourceGroup
        Location           = $_.location
        SubscriptionId     = $_.subscriptionId
        ProvisioningState  = $_.properties.provisioningState
        AccountKind        = $_.kind
        SkuName            = $_.sku.name
        SkuTier            = $_.sku.tier
        CombinedSubLocation = "$($_.subscriptionId)-$($_.location)"
    }

}

return $StorageAccounts | Group-Object -Property CombinedSubLocation

}

function GetMetricsBatchAPI ([string[]] $ResourceId, $Location) {
    # Calls the Metrics Batch API to get multiple metrics in a single call

    $resultHash=@{}

    $headers=@{
        "Content-Type"  = 'application/json'
        "Authorization" = "Bearer $AzMonitorToken"
    }

    $SubscriptionId = ($ResourceId[0] -split '/')[2]


    $Payload=@{
        "resourceids" = $ResourceId
    } | ConvertTo-Json -Depth 4

    $starttime = (Get-Date).AddHours(-1).ToString("o")

    $MetricNamespace = "microsoft.storage/storageaccounts"
    $MetricNames     = "UsedCapacity,Ingress,Egress"
    $Url="https://$($Location).metrics.monitor.azure.com/subscriptions/{0}/metrics:getBatch?metricnamespace={1}&metricnames={2}&starttime={3}&aggregation=average&api-version=2023-10-01" -f $SubscriptionId, $MetricNamespace, $MetricNames,$starttime

    $Metrics=Invoke-RestMethod -Method POST -UseBasicParsing -Uri $Url -Headers $headers -Body $Payload -ContentType 'application/json'

    #return $Metrics
    if ($Metrics -and $Metrics.values.count -gt 0) {


        $Metrics.values | foreach {

            $CurrentResourceId = $_.resourceId
            $_.value | foreach {

                $CurrentMetric = $_
                $CurrentMetricName = $CurrentMetric.name.value

                try {
                $CurrentMetric.timeseries.data[-1] | Get-Member -MemberType NoteProperty | foreach {
                    if ($_.Name -ne "timeStamp") {
                        $currentAggregation = $_.Name
                        $valueName = "$CurrentMetricName`_$currentAggregation"
                        #write-warning "Processing Metric $valueName for Resource $CurrentResourceId"
                        $resultHash[$CurrentResourceId]+=@{"$valueName" = $CurrentMetric.timeseries.data[-1].$($_.Name)}
                    }
                }
            } catch {}


        }}
        return $resultHash

    } else {
        return @{}
    }
}

###########################################
# MAIN
###########################################

$Tenant="xxxx"
Connect-AzAccount -Tenant $Tenant

$GlobalToken = UnwrapSecureString -SecureString (Get-AzAccessToken -AsSecureString).Token
$AzMonitorToken = UnwrapSecureString -SecureString (Get-AzAccessToken -AsSecureString -ResourceUrl "https://metrics.monitor.azure.com/" ).Token

$StorageAccountsBySubAndLocation = GetStorageAccountBySubAndLocation

$Metrics=@()
$SAArray=@()

$StorageAccountsBySubAndLocation | ForEach-Object {


    $SubscriptionId = $_.Group.subscriptionId | Select -First 1
    $Location       = $_.Group.location | Select -First 1
    $SAcount        = $_.Group.Count
    $AccountIds     = $_.Group.Id | Select -First 50

    Write-warning "Processing $SAcount Storage Accounts in Subscription $SubscriptionId at Location $Location"
    if ($SAcount -gt 50) {
        Write-Warning "############ Only the first 50 Storage Accounts will be processed #######"
    }
    $MetricResults = GetMetricsBatchAPI -ResourceId $AccountIds -Location $Location

    $_.Group | ForEach-Object {
        $CurrentSAId = $_.Id
        $MetricData = $MetricResults[$CurrentSAId]
        $SARecord=$_

        $MetricData.keys | ForEach-Object {

            try {
                $SARecord | Add-Member -MemberType NoteProperty -Name $_ -Value $MetricData[$_] -Force
            } catch {
             
            }
        }

        $SAArray+= $SARecord
    }


}

$SAArray | Export-Csv -Path ".\storage-account-size-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" -NoTypeInformation -Encoding UTF8