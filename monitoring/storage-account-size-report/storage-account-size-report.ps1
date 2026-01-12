function InvokeResourceExplorerQuery ($KQL,$SkipToken) {
    # Runs a KQL Query against Azure Resource Graph

    $headers=@{
        "Content-Type"  = 'application/json'
        "Authorization" = "Bearer $GlobalToken"
    }

    if ($SkipToken) {
        $Payload=@{
            "Query"=$KQL
            "options"=@{
                '$SkipToken'=$SkipToken
            }
        } | ConvertTo-Json

    } else {

        $Payload=@{
            "Query"=$KQL
        } | ConvertTo-Json

    }





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

function distribute-groups ($GroupedObjects,$MaxSize=50) {
    # Splits groups larger than $MaxSize into multiple groups of max $MaxSize items

    $ResultGroups=@()

    foreach ($group in $GroupedObjects) {
        $GroupCount = $group.Count
        if ($GroupCount -le $MaxSize) {
            $ResultGroups += $group
        } else {
            $SubGroups = [math]::Ceiling($GroupCount / $MaxSize)
            for ($i=0; $i -lt $SubGroups; $i++) {
                $StartIndex = $i * $MaxSize
                $EndIndex = [math]::Min($StartIndex + $MaxSize - 1, $GroupCount - 1)
                $NewGroupItems = $group.Group[$StartIndex..$EndIndex]
                $NewGroup = [PSCustomObject]@{
                    Name = "$($group.Name)-part$i"
                    Count = $NewGroupItems.Count
                    Group = $NewGroupItems
                }
                $ResultGroups += $NewGroup
            }
        }
    }

    return $ResultGroups
}

function GetStorageAccountBySubAndLocation {

$StorageAccounts=@()
$NoMore=$false

$FilteredKQL=@"
    resources
    | where type == 'microsoft.storage/storageaccounts'
    | project id, name, resourceGroup, location, subscriptionId,kind,sku,encryption=properties.encryption

"@

    while ($NoMore -eq $false) {

        if ($SkipToken) {
            $GetSAResults=InvokeResourceExplorerQuery -KQL $FilteredKQL -SkipToken $SkipToken
        } else {
            $GetSAResults=InvokeResourceExplorerQuery -KQL $FilteredKQL
        }

        write-warning "Retrieved $($GetSAResults.count) Storage Accounts"
        $StorageAccounts=$GetSAResults.data | foreach {
            [PsCustomObject]@{
                Id                 = $_.id
                StorageAccountName = $_.name
                ResourceGroup      = $_.resourceGroup
                Location           = $_.location
                SubscriptionId     = $_.subscriptionId
                AccountKind        = $_.kind
                SkuName            = $_.sku.name
                SkuTier            = $_.sku.tier
                EncryptionSettings = $_.encryption
                CombinedSubLocation = "$($_.subscriptionId)-$($_.location)"
            }
        }

        if ($GetSAResults.'$skipToken') {
            $SkipToken = $GetSAResults.'$skipToken'
        } else {
            $NoMore=$true
        }
    }

return distribute-groups ($StorageAccounts | Group-Object -Property CombinedSubLocation)

}

function GetMetricsBatchAPI ([string[]] $ResourceId, $Location,$MetricNamespace,$MetricNames, $Hash) {
    # Calls the Metrics Batch API to get multiple metrics in a single call

    $headers=@{
        "Content-Type"  = 'application/json'
        "Authorization" = "Bearer $AzMonitorToken"
    }

    $SubscriptionId = ($ResourceId[0] -split '/')[2]

    # Inspect MetricNamespace, if more than 2 levels, then assume a subresource
    if ( ($MetricNamespace -split '/').Count -gt 2) {
        $SubResource = "/$(($MetricNamespace -split '/')[-1])"

        $ResourceId = $ResourceId | foreach {
            "$_$SubResource/default"
        }

    } else {
        $SubResource = ""
    }

    $Payload=@{
        "resourceids" = $ResourceId
    } | ConvertTo-Json -Depth 4

    $starttime = (Get-Date).AddHours(-1).ToString("o")


    $Url="https://$($Location).metrics.monitor.azure.com/subscriptions/{0}/metrics:getBatch?metricnamespace={1}&metricnames={2}&starttime={3}&aggregation=average&api-version=2023-10-01" -f $SubscriptionId, $MetricNamespace, $MetricNames,$starttime
    $Metrics=Invoke-RestMethod -Method POST -UseBasicParsing -Uri $Url -Headers $headers -Body $Payload -ContentType 'application/json'

    #return $Metrics
    if ($Metrics -and $Metrics.values.count -gt 0) {
        
        $Metrics.values | foreach {
            
            $CurrentResourceId = $_.resourceId
            $CurrentResourceIdArray = $CurrentResourceId -split '/'

            if ($CurrentResourceIdArray.Count -eq 11) {
                # Remove the subresource so that hashing is against the parent resource
                $CurrentResourceId = $CurrentResourceIdArray[0..($CurrentResourceIdArray.Count-3)] -join '/'
            }



            $_.value | foreach {
                


                $CurrentMetric = $_
                $CurrentMetricName = $CurrentMetric.name.value
                try {
                if ($CurrentMetric.timeseries.data.count -gt 0){
                        $CurrentMetric.timeseries.data[-1] | Get-Member -MemberType NoteProperty | foreach {
                        if ($_.Name -ne "timeStamp") {
                            $currentAggregation = $_.Name
                            $valueName = "$(($MetricNamespace -split '/')[-1])`_$CurrentMetricName`_$currentAggregation"
                            #write-warning " --- $ValueName"
                            if (-not $Hash.ContainsKey($CurrentResourceId)) {
                                $Hash[$CurrentResourceId] = @{}
                            }

                            $Hash[$CurrentResourceId]+=@{"$valueName" = $CurrentMetric.timeseries.data[-1].$($_.Name)}

                        }
                    }
                }
                } catch {
                    write-warning $($CurrentMetric | ConvertTo-Json -Depth 10    )
                }

        }
    }
        return $resultHash

    } else {
        write-warning "No Metrics returned from Metrics Batch API"
        return @{}
    }
}



function Mockgroup(){
    # Mock function for testing
    $MockData=@()
    for ($i=1; $i -le 120; $i++) {
        $MockData += [PsCustomObject]@{
            Id                 = "/subscriptions/xxxx/resourceGroups/rg$i/providers/Microsoft.Storage/storageAccounts/sa$i"
            StorageAccountName = "sa$i"
            ResourceGroup      = "rg$i"
            Location           = "eastus"
            SubscriptionId     = "xxxx"
            AccountKind        = "StorageV2"
            SkuName            = "Standard_LRS"
            SkuTier            = "Standard"
            CombinedSubLocation = "xxxx-eastus"
        }
    }

    return $MockData | Group-Object -Property CombinedSubLocation
}

###########################################
# MAIN
###########################################









$Tenant="xxxx"
$Global:ThrottlePreventionInterval = 40


try {
    Connect-AzAccount -Tenant $Tenant

    $GlobalToken = UnwrapSecureString -SecureString (Get-AzAccessToken -AsSecureString).Token
    $AzMonitorToken = UnwrapSecureString -SecureString (Get-AzAccessToken -AsSecureString -ResourceUrl "https://metrics.monitor.azure.com/" ).Token

    $StorageAccountsBySubAndLocation = GetStorageAccountBySubAndLocation

    $StorageAccountsBySubAndLocation | ft   Count,Name 
    pause

    $Metrics=@()

    $RequestCount=0
    $TotalRequestCount=0
    $SAArray=@()

    $StorageAccountsBySubAndLocation | ForEach-Object {


        $SubscriptionId = $_.Group.subscriptionId | Select -First 1
        $Location       = $_.Group.location | Select -First 1
        $SAcount        = $_.Group.Count
        $AccountIds     = $_.Group.Id

        Write-warning "[$TotalRequestCount] Processing $SAcount Storage Accounts in Subscription $SubscriptionId at Location $Location"

        $MetricResults = @{}

        # All accounts should have this metric
        GetMetricsBatchAPI `
            -ResourceId $AccountIds `
            -Location $Location `
            -MetricNamespace "microsoft.storage/storageaccounts" `
            -MetricNames "UsedCapacity,Ingress,Egress" `
            -Hash $MetricResults


        # Only run this if there are StorageV2 or BlockBlobStorage accounts in the group
        if ($_.Group | Where-Object {$_.AccountKind -eq "StorageV2" -or $_.AccountKind -eq "BlockBlobStorage"}) {
        
            GetMetricsBatchAPI `
            -ResourceId $AccountIds `
            -Location $Location `
            -MetricNamespace "microsoft.storage/storageaccounts/blobservices" `
            -MetricNames "ContainerCount,BlobCapacity,BlobCount,Ingress,Egress,Transactions" `
            -Hash $MetricResults


        } else {write-warning "Skipping Blob metrics"}

        # Only run this if there are StorageV2 Standard accounts in the group    
        if ($_.Group | Where-Object { $_.AccountKind -eq "StorageV2" -and $_.SkuTier -eq "Standard" }) {

        
        GetMetricsBatchAPI `
            -ResourceId $AccountIds `
            -Location $Location `
            -MetricNamespace "microsoft.storage/storageaccounts/fileservices" `
            -MetricNames "FileCapacity,FileCount,FileShareCount,Ingress,Egress,Transactions" `
            -Hash $MetricResults

        GetMetricsBatchAPI `
            -ResourceId $AccountIds `
            -Location $Location `
            -MetricNamespace "microsoft.storage/storageaccounts/queueservices" `
            -MetricNames "QueueMessageCount,QueueCount,QueueCapacity,Ingress,Egress,Transactions" `
            -Hash $MetricResults

        GetMetricsBatchAPI `
            -ResourceId $AccountIds `
            -Location $Location `
            -MetricNamespace "microsoft.storage/storageaccounts/tableservices" `
            -MetricNames "TableCapacity,TableCount,TableEntityCount,Ingress,Egress,Transactions" `
            -Hash $MetricResults
        } else {write-warning "Skipping Files,Queue,Table metrics"}


        $_.Group | ForEach-Object {
            $CurrentSAId = $_.Id
            
            if ($CurrentSAId -and $MetricResults.ContainsKey($CurrentSAId)) {
            $MetricData = $MetricResults[$CurrentSAId]
            } else {
                $MetricData = @{}
            }
            
            $SARecord=$_

            $MetricData.keys | ForEach-Object {

                try {
                    $SARecord | Add-Member -MemberType NoteProperty -Name $_ -Value $MetricData.$_ -Force
                } catch {
                
                }
            }

            $SAArray+= $SARecord

            $RequestCount++
            $TotalRequestCount++
            if ($RequestCount -gt $Global:ThrottlePreventionInterval) {
                Write-Host "Sleeping 45 seconds to prevent throttling."
                Start-Sleep $Global:ThrottlePreventionInterval
                $RequestCount=0
            }
        
        }
    }
} catch {
    Write-Error $_.Exception.Message
}

if ($SAArray) {
    $SAArray | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\storage-account-size-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json" -Encoding UTF8
    $SAArray | Export-Csv -Path ".\storage-account-size-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" -NoTypeInformation -Encoding UTF8
}