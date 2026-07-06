Param
(
  [Parameter (Mandatory=$false)]
  [String] $fwName = "",
  [Parameter (Mandatory=$false)]
  [String] $RG = "",
  [Parameter (Mandatory=$false)]
  [String] $VNETName = "",
  [Parameter (Mandatory=$false)]
  [String] $FWPublicIPName = "",
  [Parameter (Mandatory=$false)]
  [String] $FWMGMTIPName ="",
  [Parameter (Mandatory=$false)]
  [String] $FWMGMTIPRG ="",
  [Parameter (Mandatory=$false)]
  [String] $FWSubName = ""
)


Write-Verbose "Enabling $fwName on vnet $VNETName with public ip $FWPublicIPName and in RG $RG / $FWSubName"

Write-Verbose "Authenticating...."
# Authenticate using Managed Identity
Login-AzAccount -Identity
   
Select-AzSubscription -SubscriptionName $FWSubName

# =======PERFORM THE WORK=====================

        
        # Start the Azure Firewall
        Write-Verbose "Reading existing Firewall object ..."
        $fwObject           = Get-AzFirewall -Name $fwName -ResourceGroupName $RG

        Write-Verbose "Reading Virtual network ..."
        $vnetObject         = Get-AzVirtualNetwork -ResourceGroupName $RG -Name $VNETName
        Write-Verbose "$($vnetObject.id)"

        Write-Verbose "Reading Public IP ..."
        $fwPublicIP         = Get-AzPublicIpAddress -ResourceGroupName $RG -Name $FWPublicIPName
        Write-Verbose "$($fwPublicIP.id)"

        If ($FWMGMTIPName -ne $null -and $FWMGMTIPName -ne "") {
            Write-Verbose "Reading MGMT IP ..."
            $mgmtPublicIP       = Get-AzPublicIpAddress -ResourceGroupName $FWMGMTIPRG -Name $FWMGMTIPName
            Write-Verbose "$($mgmtPublicIP.id)"
            $fwObject.Allocate($vnetObject, $fwPublicIP,$mgmtPublicIP)
        } else {
            $fwObject.Allocate($vnetObject, $fwPublicIP)
        }

        Write-Verbose "Begin Azure Firewall Allocation method ..."
        
        Set-AzFirewall -AzureFirewall $fwObject -debug
        Write-Verbose "Done"

 

    
# ===========================================