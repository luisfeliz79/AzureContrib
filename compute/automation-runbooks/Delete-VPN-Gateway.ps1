Param
(
  [Parameter (Mandatory=$false)]   [String] $GW_NAME = "",
  [Parameter (Mandatory=$false)]   [String] $RG = "",
  [Parameter (Mandatory=$false)]   [String] $LNG_NAME = "",
  [Parameter (Mandatory=$false)]   [String] $VPN_CONN_NAME = "",
  [Parameter (Mandatory=$false)]   [String] $VpnGWSubName = ""
  
)


Write-Output "Authenticating...."

# Authenticate using Managed Identity
az login --identity 
az account set --subscription $VpnGWSubName


Write-Output "Deleting Connection $VPN_CONN_NAME in RG: $RG"
az network vpn-connection delete -g $RG -n $VPN_CONN_NAME

Write-Output "Deleting vnet-gateway $GW_NAME in RG: $RG"
az network vnet-gateway delete -g $RG -n $GW_NAME
