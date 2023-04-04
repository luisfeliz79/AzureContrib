#Input params to be modified as needed
$FirewallResourceGroup = "hub-firewall-eastus"
$FirewallName = "luisfweastus"
$FirewallPolicyResourceGroup = "hub-firewall-eastus"
$FirewallPolicyName = "test"

try {
  Write-warning "Getting Firewall Info"
  $azfw = Get-AzFirewall -Name $FirewallName -ResourceGroupName $FirewallResourceGroup -ErrorAction Stop
} catch {
  Write-Error "Could not find Firewall $FirewallName in resource Group $FirewallResourceGroup "
  break
}

Try {
  Write-warning "Getting Policy Info"
  $fwpolicy = Get-AzFirewallPolicy -Name $FirewallPolicyName -ResourceGroupName $FirewallPolicyResourceGroup -ErrorAction Stop
} catch {
  Write-Error "Could not find Firewall Policy $FirewallPolicyName in resource group FirewallPolicyResourceGroup"
  break
}
Write-Warning "Checking SNAT Settings"
# Check NAT
if ($azfw.PrivateRange.count -ne $fwpolicy.PrivateRange.count ) {$SNatMatch=$false} else {$SNatMatch -eq $True}

Write-warning "Checking Rules"
# Check Rules
$RuleGroupsToCheck=$fwpolicy.RuleCollectionGroups.id    

$FwPolicyRulesObject=$RuleGroupsToCheck | ForEach-Object {

  $RuleGroupName = ($_ -split '/')[-1]
  $RuleGroupResourceGroup =($_ -split '/')[-7]  

  Write-warning " - Rule Group: $RuleGroupName"
  $RuleGroup= Get-AzFirewallPolicyRuleCollectionGroup -ResourceName $RuleGroupName `
                                          -ResourceGroupName $RuleGroupResourceGroup `
                                          -AzureFirewallPolicyName $FirewallPolicyName

                                          
  
  $RuleGroup.properties.RuleCollection | ForEach-Object {
    [pscustomobject]@{
      RuleGroupName = $RuleGroup.Name
      Name          = $_.Name
      Action        = $_.action.Type
      RuleType      = ($_.RulesText | convertfrom-json).ruleType
    }
  }



}

$FwPolicyAppRuleCount=($FwPolicyRulesObject | where RuleType -eq "ApplicationRule").count
$FwPolicyNetRuleCount=($FwPolicyRulesObject | where RuleType -eq "NetworkRule").count
$FwPolicyNATRuleCount=($FwPolicyRulesObject | where RuleType -eq "NatRule").count

# Report

$Assessment=[PsCustomObject]@{
  # Check Location
  LocationMatch=$azfw.Location -eq $fwpolicy.Location
  # Check SKU
  SkuMatch=$fwpolicy.sku.Tier -eq $azfw.Sku.Tier 
  # SNAT
  SNATMatch = $SNatMatch
  # Get Rule Counts
  AzFirewallApplicationRuleCount = $azfw.ApplicationRuleCollections.count
  PolicyApplicationRuleCount     = $FwPolicyAppRuleCount
  AzFirewallNetworkRuleCount     = $azfw.NetworkRuleCollections.count
  PolicyNetworkRuleCount         = $FwPolicyNetRuleCount
  AzFirewallNATRulesCount        = $azFw.NatRuleCollections.count
  PolicyNATRulesCount            = $FwPolicyNATRuleCount
}
$Assessment


