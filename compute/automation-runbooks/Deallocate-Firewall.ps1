Param
(
  [Parameter (Mandatory=$false)]   [String] $fwName = "",
  [Parameter (Mandatory=$false)]   [String] $RG = "",
  [Parameter (Mandatory=$false)]   [String] $FWSubName = ""
  
)


# Authenticate using Managed Identity
Login-AzAccount -Identity


 
Select-AzSubscription -SubscriptionName $FWSubName

# =======PERFORM THE WORK=====================

        
        # Start the Azure Firewall
        Write-Verbose "Reading existing Firewall object ..."
        $fwObject           = Get-AzFirewall -Name $fwName -ResourceGroupName $RG

        $fwObject 

        if ((($fwObject).IpConfigurationsText | convertfrom-json).name -eq "") {
            Write-Output "No Active Firewalls found on $Subscription. Exiting..."
            
            break
        }
 
        # Stop the Azure Firewalls
        $fwObject | ForEach-Object { 
            if ($_.ProvisioningState -eq "Succeeded") {
                Write-Output "Stopping $($_.id)"
                Write-Output "Deallocating $($_.id)"
                $_.Deallocate()
                Set-AzFirewall -AzureFirewall $_
            }
        }
 

    
# ===========================================





