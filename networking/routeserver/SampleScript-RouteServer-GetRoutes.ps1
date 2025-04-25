# Sample script
# Checks Learned and Advertised routes accross all peers of one ore more Route Server instances.

$RouteServers=@()
$RouteServers+=@{
    Name="RouteServer1"
    ResourceGroupName="cisco-nvas-chaos"
    SubscriptionName="xxxxx"
}

# $RouteServers+=@{
#     Name="RouteServer2"
#     ResourceGroupName="cisco-nvas-chaos2"
#     SubscriptionName="xxxx"
# }

# First, we must connect
# Connect-Azaccount -Tenant xxxxx

$RouteEntryDetails = @()

function Write-Status {
    param (
        [string]$Message
    )
    Write-Warning "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

Try {


    $RouteServers | ForEach-Object {
        $RouteServerName = $_.Name
        $ResourceGroupName = $_.ResourceGroupName
        $SubscriptionName = $_.SubscriptionName
        $ExportFileName = "RouteServerRoutes-$RouteServerName-$((Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")).csv"


        # Set the context to the specified subscription
        Write-Status "Setting context to subscription: $SubscriptionName"
        Set-AzContext -SubscriptionName $SubscriptionName

        # Get information about the Route Server
        Write-Status "Getting information for Route Server: $RouteServerName in Resource Group: $ResourceGroupName"
        $rsInfo = Get-AzRouteServer -ResourceGroupName $ResourceGroupName -RouteServerName $RouteServerName

        # List of Peerings
        $Peers = $rsInfo.Peerings

        # For Each peering
        $Peers | ForEach-Object {
            $PeerName = $_.Name
            $PeerIP = $_.PeerIp
            $PeerASN = $_.PeerAsn

            # Get the advertised routes for the route server
            Write-Status "Getting advertised routes for Peer: $PeerName in Route Server: $RouteServerName"
            $advertisedRoutes = Get-AzRouteServerPeerAdvertisedRoute -ResourceGroupName $ResourceGroupName -RouteServerName $RouteServerName -peerName $_.Name

            $advertisedRoutes | ForEach-Object {
            $Detail= [PsCustomObject]@{
                    TimeGenerated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    Type = "Advertised"
                    RouteServerName = $RouteServerName
                    #ResourceGroupName = $ResourceGroupName
                    PeerName = $PeerName
                    PeerStatus = $PeerIP
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

            $LearnedRoutes | ForEach-Object {
            $Detail =    [PsCustomObject]@{
                    TimeGenerated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    Type = "Learned"
                    RouteServerName = $RouteServerName
                    #ResourceGroupName = $ResourceGroupName
                    PeerName = $PeerName
                    PeerStatus = $PeerIP
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

            # Display the Route Entry Details in a formatted table
            $RouteEntryDetails | Format-Table -wrap -AutoSize

            # Optionally, export it to a CSV file
            $RouteEntryDetails | Export-Csv -Path $ExportFileName -NoTypeInformation -Force
            Write-Status "Complete. Exported Route Entry Details to $pwd\$ExportFileName"
    }

    }

} 
Catch {
    Write-Error "An error occurred: $_"

    Write-Host "Have you logged in to Azure?"
    Write-Host " Use Connect-AzAccount -UseDeviceAuthentication"
    Write-Host ""
    Write-host "Do you have the correct permissions to access the Route Server?"
    Write-Host "  Contributor role is required"
}



