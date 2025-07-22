# Input bindings are passed in via param block.
param($Timer)

function Write-Status {
    param (
        [string]$Message
    )
    Write-Warning "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

function UnwrapSecureString() {
    param (
        [Parameter(Mandatory = $true)]
        $SecureString
    )

    $incomingType = $SecureString.GetType().Name
    Write-Status "Unwrapping SecureString of type: $incomingType"
    if ($incomingType -eq "String") {
        Write-Status "Got a string, so just returning the value as is"
        return $SecureString
    } else {
        Write-Status "Unwrapping SecureString"
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }

}

function SendLogToWorkspace ($logObject,$bearerToken) {

    $payloadArray = @()

    Try {
    
        Write-Status "Sending Log data ... "
    
        # First Examing the log object
        if ($logObject -eq $null) {
            Write-Status "SKIPPING: Log Object is null"
            return
        }


    
        if ($logObject.count -lt 2) {    
             Write-Status " Single entry ... "
             $body = "[" + $( $logObject | ConvertTo-Json) + "]"
             $payloadArray += $body    
        } else {
            Write-Status " Multi entry ... "

            # Max payload size is 1Mb, so we need to split the logObject if it exceeds this size
            # lets use 80% of 1Mb to be safe
            $maxPayloadSize = 1024 * 1024 * 0.80 # 80% of 1Mb
            #Lets sample a record size
            $sampleRecordSize = ($logObject | Select-Object -First 1 | ConvertTo-Json).Length

            $splitSize = [math]::Floor($maxPayloadSize / $sampleRecordSize)
            if ($splitSize -gt 1000) {
                # Extra safety check to avoid too large payloads
                Write-Status "Split size is too large, limiting to 1000 records per payload"
                $splitSize = 1000 # Limit to 1000 records per payload
            }
            Write-Status "Sample record size: $sampleRecordSize bytes, split size: $splitSize records per payload"

            $tmpBodyArray = @()
            $logObject | ForEach-Object {
                
                if ($tmpBodyArray.Count -le $splitSize) {
                    $tmpBodyArray += $_
                } else {
                    # Ok, lets split and add to payloadArray, then clear tmpBodyArray
                    Write-warning "Split"
                    $payloadArray += ($tmpBodyArray | ConvertTo-Json -Depth 99)
                    $tmpBodyArray = @()
                }
            }
            # Add the remaining records to the payloadArray
            if ($tmpBodyArray.Count -gt 0) {
                $payloadArray += ($tmpBodyArray | ConvertTo-Json -Depth 99)
            }
 

        }
 
        Write-Status " [ $MONITOR_DCR_IMMUTABLE_ID ] "
    
        # Prepare the request headers and URI
        $headers = @{"Authorization"="Bearer $(UnwrapSecureString -SecureString $bearerToken)";"Content-Type"="application/json"};

        $uri = "$MONITOR_ENDPOINT_URI/dataCollectionRules/$MONITOR_DCR_IMMUTABLE_ID/streams/$($MONITOR_STREAM_NAME)?api-version=$MONITOR_API_VERSION"
        Write-Status "URI: $uri"


        Write-Status "Sending $($payloadArray.Count) payloads to the workspace..."
        $payloadArray | ForEach-Object {
            $body = $_
            Write-Status "Sending payload of size: $($body.Length) bytes"
    
            $uploadResponse = Invoke-WebRequest -Uri $uri -Method "Post" -Body $body -Headers $headers   -UseBasicParsing
    
            Write-Status "$($uploadResponse.StatusCode) SUCCESS"
        }

    } catch {
    
        Write-Status "Error"
        $_
        $uploadResponse

    }
}


function GetRSRoutes ($RSId,$ERGWid) {

    $RouteEntryDetails = @()

    $RS_Name=($RSId -split '/')[-1]
    $RS_RG=($RSId -split '/')[4]
    $RS_SUB=($RSId -split '/')[2]

    $ERGW_name=($ERGWid -split '/')[-1]
    $ERGW_RG=($ERGWid -split '/')[4]
    $ERGW_SUB=($ERGWid -split '/')[2]

    Try {
    
        $RouteServerName = $RS_Name
        $ResourceGroupName = $RS_RG
        $SubscriptionName = $RS_SUB
        
        # Set the context to the specified subscription
        Write-Status "Setting context to subscription: $SubscriptionName"
        Set-AzContext -SubscriptionName $SubscriptionName | Out-Null

        # Get information about the Route Server
        Write-Status "Getting information for Route Server: $RouteServerName in Resource Group: $ResourceGroupName"
        $rsInfo = Get-AzRouteServer -ResourceGroupName $ResourceGroupName -RouteServerName $RouteServerName

        # List of Peerings
        $Peers = $rsInfo.Peerings

        Write-Status "Found $($Peers.Count) peerings in Route Server: $RouteServerName"

        # For Each peering
        $Peers | ForEach-Object {
            $PeerName = $_.Name
            $PeerIP = $_.PeerIp
            $PeerASN = $_.PeerAsn
            #write-Status "$($_ | convertTo-json -depth 10)"
            # Get the advertised routes for the route server
            Write-Status "Getting advertised routes for Peer: $PeerName in Route Server: $RouteServerName"
            $advertisedRoutes = Get-AzRouteServerPeerAdvertisedRoute -ResourceGroupName $ResourceGroupName -RouteServerName $RouteServerName -peerName $_.Name
            if ($advertisedRoutes -eq $null) {
                Write-Status "No advertised routes found for Peer: $PeerName in Route Server: $RouteServerName"
                
            } else {
                Write-Status "Found $($advertisedRoutes.Count) advertised routes for Peer: $PeerName in Route Server: $RouteServerName"
            }
            $advertisedRoutes | ForEach-Object {
            $Detail= [PsCustomObject]@{
                    #TimeGenerated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    RouteType = "Advertised"
                    RouteServerName = $RouteServerName
                    ResourceGroupName = $ResourceGroupName
                    PeerName = $PeerName
                    PeerASN = $PeerASN
                    RSInstance = $_.LocalAddress
                    Network = $_.Network
                    NextHop = $_.NextHop
                    Origin = $_.Origin
                    SourcePeer = $_.SourcePeer
                    AsPath = $_.AsPath
                    Weight = $_.Weight
                }
            
                
                $RouteEntryDetails += $Detail
                
            }

            # Get the Learned routes for the route server
            Write-Status "Getting learned routes for Peer: $PeerName in Route Server: $RouteServerName"
            $LearnedRoutes = Get-AzRouteServerPeerLearnedRoute -ResourceGroupName $ResourceGroupName -RouteServerName $RouteServerName -peerName $_.Name
            if ($LearnedRoutes -eq $null) {
                Write-Status "No learned routes found for Peer: $PeerName in Route Server: $RouteServerName"
                
            } else {
                Write-Status "Found $($LearnedRoutes.Count) learned routes for Peer: $PeerName in Route Server: $RouteServerName"
            }
            $LearnedRoutes | ForEach-Object {
            $Detail =    [PsCustomObject]@{
                    #TimeGenerated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    RouteType = "Learned"
                    RouteServerName = $RouteServerName
                    ResourceGroupName = $ResourceGroupName
                    PeerName = $PeerName
                    PeerASN = $PeerASN
                    RSInstance = $_.LocalAddress
                    Network = $_.Network
                    NextHop = $_.NextHop
                    Origin = $_.Origin
                    SourcePeer = $_.SourcePeer
                    AsPath = $_.AsPath
                    Weight = $_.Weight
                }

                
                $RouteEntryDetails += $Detail
                
            }


        }

        # Get the Learned routes for the ERGW
        Write-Status "Getting learned routes by the GW: $ERGW_name"
        $LearnedRoutes = Get-AzVirtualNetworkGatewayLearnedRoute -VirtualNetworkGatewayName $ERGW_name -ResourceGroupName $ERGW_RG
        if ($LearnedRoutes -eq $null) {
            Write-Status "No learned routes found for GW: $ERGW_name"
            
        } else {
            "Found $(($LearnedRoutes | where SourcePeer -in $rsInfo.RouteServerIps).Count) learned routes for GW: $ERGW_name"
        }
        $LearnedRoutes | ForEach-Object {

        if ($rsInfo.RouteServerIps -contains $_.SourcePeer) {

            $PeerName = "Gateway_$($_.LocalAddress)"
            $PeerASN=""

            $Detail =    [PsCustomObject]@{
                    #TimeGenerated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    RouteType = "Advertised"
                    RouteServerName = $RouteServerName
                    ResourceGroupName = $ResourceGroupName
                    PeerName = $PeerName
                    PeerASN = $PeerASN
                    RSInstance = $_.SourcePeer
                    Network = $_.Network
                    NextHop = $_.NextHop
                    Origin = $_.Origin
                    SourcePeer = $_.SourcePeer
                    AsPath = $_.AsPath
                    Weight = $_.Weight
                }

                
                $RouteEntryDetails += $Detail
        } 
        }

        # Get advertised routes by the ERGW
        $rsInfo.RouteServerIps | ForEach {
            $InstanceIP = $_
            Write-Status "Getting advertised routes by the GW: $ERGW_name (Learned by RS instance $InstanceIP)"
            $AdvertisedRoutes = Get-AzVirtualNetworkGatewayAdvertisedRoute -VirtualNetworkGatewayName $ERGW_name -ResourceGroupName $ERGW_RG -Peer $InstanceIP
            if ($AdvertisedRoutes -eq $null) {
                Write-Status "No advertised routes found for GW: $ERGW_name"

            } else {
                Write-Status "Found $(($AdvertisedRoutes).Count) advertised routes for GW: $ERGW_name (Learned by RS instance $InstanceIP)"
            }

            $AdvertisedRoutes | ForEach-Object {

            $PeerName = "Gateway_$($_.LocalAddress)"
            $PeerASN=""

            $Detail =    [PsCustomObject]@{
                    #TimeGenerated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    RouteType = "Learned"
                    RouteServerName = $RouteServerName
                    ResourceGroupName = $ResourceGroupName
                    PeerName = $PeerName
                    PeerASN = $PeerASN
                    RSInstance = $InstanceIP
                    Network = $_.Network
                    NextHop = $_.NextHop
                    Origin = $_.Origin
                    SourcePeer = $_.SourcePeer
                    AsPath = $_.AsPath
                    Weight = $_.Weight
                }

                
                $RouteEntryDetails += $Detail
                
            }
        }



    $RouteEntryDetails

    } 
    Catch {
        Write-Error "An error occurred: $_"
    }

}

$MONITOR_API_VERSION       = "2023-01-01"
$MONITOR_STREAM_NAME       = "Custom-log" #name of the stream in the DCR that represents the destination table

$MONITOR_ENDPOINT_URI      = $ENV:MONITOR_ENDPOINT_URI
$MONITOR_DCR_IMMUTABLE_ID  = $ENV:MONITOR_DCR_IMMUTABLE_ID
$ROUTE_SERVER_ID           = $ENV:ROUTE_SERVER_ID
$ERGW_ID                   = $ENV:ERGW_ID

if (-not $MONITOR_ENDPOINT_URI) {
    Write-Error "MONITOR_ENDPOINT_URI environment variable is not set."
    exit 1
}
if (-not $MONITOR_DCR_IMMUTABLE_ID) {
    Write-Error "MONITOR_DCR_IMMUTABLE_ID environment variable is not set."
    exit 1
}
if (-not $ROUTE_SERVER_ID) {
    Write-Error "ROUTE_SERVER_ID environment variable is not set."
    exit 1
}
if (-not $ERGW_ID) {
    Write-Error "ERGW_ID environment variable is not set."
    exit 1
}
# Get the routes from the Route Server
$StartTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Routes = GetRSRoutes -RSId $ROUTE_SERVER_ID -ERGWid $ERGW_ID

# Add a RunId to each route entry
$event_guid = [guid]::NewGuid().ToString()
$Routes | ForEach-Object {
    $_ | Add-Member -MemberType NoteProperty -Name "RunId" -Value $event_guid -Force
    $_ | Add-Member -MemberType NoteProperty -Name "TimeGenerated" -Value $StartTime -Force
}

# Get the bearer token for authentication
$bearerToken = (Get-AzAccessToken -ResourceUrl "https://monitor.azure.com").Token

# Send the routes to the Log Analytics workspace
SendLogToWorkspace -logObject $Routes -bearerToken $bearerToken

