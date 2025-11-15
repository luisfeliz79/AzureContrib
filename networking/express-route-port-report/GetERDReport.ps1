$PortLocations=Get-AzExpressRoutePortsLocation

$Counter=$PortLocations.Count
$Throttleguard=15
$ThrottleGuardCounter=0

$PortLocationsReport=@()

$PortLocations | where name -ne "CDC-Canberra-CBR20" | ForEach-Object {
    $Location = $_

    Write-Host "Processing location $($Location.Name) ($Counter remaining)"
    $Counter--
    $ThrottleGuardCounter++
    if ($ThrottleGuardCounter -ge $Throttleguard) {
        Write-Host "Throttle prevention wait for 300 seconds..."
        Start-Sleep -Seconds 300
        $ThrottleGuardCounter=0
    } else {
        Start-Sleep -Seconds (  Get-Random -Minimum 1 -Maximum 5 )
    }

    
    Try {
        $PortInfo=Get-AzExpressRoutePortsLocation -LocationName $Location.Name -ErrorAction Stop
        $PortInfoText=($PortInfo.AvailableBandwidths.offerName -join ", ")
    } Catch {
        Write-Warning "Waiting 120 seconds due to 429 Too Many Requests..."
        Start-Sleep -Seconds 120
        $PortInfoText="Error"
        
    }
    if ($PortInfoText -eq "Error") {
        try {
            Write-host "Retrying for location $($Location.Name)..."
            $PortInfo=Get-AzExpressRoutePortsLocation -LocationName $Location.Name -ErrorAction Stop
            $PortInfoText=($PortInfo.AvailableBandwidths.offerName -join ", ")
        } Catch {
            $PortInfoText="Error"
        }
    } 

        $PortLocationsReport += [PSCustomObject]@{
            PortName        = $Location.Name
            PortId          = $Location.Id
            Address         = $Location.Address
            Contact         = $Location.Contact
            ProvisioningState = $Location.ProvisioningState
            AvailableBandwidths = $PortInfoText
        }

    }
$PortLocationsReport

$PortLocationsReport | Export-Csv -Path ".\ERDPortLocationsReport.csv" -NoTypeInformation -Encoding UTF8 -Force