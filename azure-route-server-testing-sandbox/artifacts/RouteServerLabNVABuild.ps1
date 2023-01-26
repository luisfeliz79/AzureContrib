param($LocalBGPIP,$RemoteVPNIP, $RemoteVPNBGPPeerIP,$RouteServerBGPPeerIP,$SharedSecret)

$BGPRouterID=$LocalBGPIP
$BGPLocalASN="65501"

#Prereqs
$ErrorActionPreference="SilentlyContinue"
$LogPath = 'C:\WindowsAzure\Logs\RSLABBuild.log'
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $LogPath -append

#Set a Custom RDP Port
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDenyTSConnections" -Value  0
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" -Value 22389
New-NetFirewallRule -DisplayName 'RDPPORTLatest' -Profile 'Any' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22389
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile' -name "AllowLocalPolicyMerge" -Value 1
restart-service TermService -Force

reg query "HKLM\Software\Policies\Microsoft\WindowsFirewall\PublicProfile" /s
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber"
Get-NetFirewallProfile -PolicyStore ActiveStore

Set-NetFirewallProfile -Enabled false *

Install-WindowsFeature RemoteAccess
Install-WindowsFeature RSAT-RemoteAccess-PowerShell
Install-Windowsfeature Routing


# Configure VPN
install-remoteaccess -vpntype vpns2s
Start-Sleep 20 # Wait for services to start
Add-VpnS2SInterface VPN $RemoteVPNIP  -Protocol IKEv2 -AuthenticationMethod PSKOnly -SharedSecret $SharedSecret -IPv4Subnet "$($RemoteVPNBGPPeerIP)/32:1"


# Configure BGP
$TransitRouting= New-Object -TypeName Microsoft.PowerShell.Cmdletization.GeneratedTypes.Bgp.TransitRouting
$TransitRouting="Enabled"
Add-BgpRouter -BgpIdentifier   $BGPRouterID -LocalASN $BGPLocalASN -TransitRouting $TransitRouting

#Configure Router Server BGP Peer
  
  # Compute Next Hop based on the LAN interface IP and Mask
  $ip=[ipaddress]$LocalBGPIP
  $subnet=[ipaddress](Get-CimInstance  -ClassName Win32_NetworkAdapterConfiguration | where IPAddress -contains $LocalBGPIP).ipsubnet[0]
  $netid=[ipaddress]($ip.address -band $subnet.address)
  $NextHop=([ipaddress]($netid.Address+0x1+0xffffff)).IPAddressToString

  # Define static routes to RouteServer Endpoints since they are not directly connected.
  route add $RouteServerBGPPeerIP[0] mask 255.255.255.255 $NextHop -p
  route add $RouteServerBGPPeerIP[0] mask 255.255.255.255 $NextHop -p
  
  #Add both BGP Peers
  Add-BgpPeer   -LocalIPAddress  $BGPRouterID  -PeerIPAddress $RouteServerBGPPeerIP[0] -PeerASN 65515 -Name RouteServer1
  Add-BgpPeer   -LocalIPAddress  $BGPRouterID  -PeerIPAddress $RouteServerBGPPeerIP[1] -PeerASN 65515 -Name RouteServer2
  
#Configure VPN BGP Peer
Add-BgpPeer   -LocalIPAddress  $BGPRouterID  -PeerIPAddress $RemoteVPNBGPPeerIP -PeerASN 65502 -Name OnPremRouter

Set-Service RaMgmtSvc -StartupType Automatic
Set-Service RemoteAccess -StartupType Automatic

# # Configure NAT
# netsh routing ip nat install
# $LANInterface=(Get-NetIPAddress -IPAddress (Get-BgpPeer)[0].localipaddress).InterfaceAlias
# $WANInterface=(get-netroute -DestinationPrefix 0.0.0.0/0).InterfaceAlias
# netsh routing ip nat add interface name=$LANInterface mode=PRIVATE
# netsh routing ip nat add interface name=$WANInterface mode=FULL
# Add-BGPCustomRoute -Network "0.0.0.0/0"


Start-Sleep 10 
Get-VpnS2SInterface
Get-BGPPeer
Get-BgpRouteInformation

Stop-Transcript
