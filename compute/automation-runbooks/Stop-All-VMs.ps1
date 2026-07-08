# Authenticate using Managed Identity
Login-AzAccount -Identity

Get-AzSubscription | foreach {

    $Subscription = $_.Name

    Select-AzSubscription -SubscriptionName $Subscription

# =======PERFORM THE WORK=====================
    Get-AzVM -Status
    Get-AzVM | Stop-AzVM -Force -Confirm:$false
    Get-AzVM -Status
# ===========================================

}
