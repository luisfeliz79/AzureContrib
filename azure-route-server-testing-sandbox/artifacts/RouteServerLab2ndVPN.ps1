param($RemoteVPNIP, $RemoteVPNBGPPeerIP,$SharedSecret)


$BGPRouterID=(Get-BgpRouter).bgpidentifier
$BGPLocalASN="65502"

#Prereqs
$ErrorActionPreference="SilentlyContinue"
$LogPath = 'C:\WindowsAzure\Logs\RSLABAdd2ndVPNandPeer.log'
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $LogPath -append

Add-VpnS2SInterface VPN2 $RemoteVPNIP  -Protocol IKEv2 -AuthenticationMethod PSKOnly -SharedSecret $SharedSecret -IPv4Subnet "$($RemoteVPNBGPPeerIP)/32:1"


#Configure VPN BGP Peer
Add-BgpPeer   -LocalIPAddress  $BGPRouterID  -PeerIPAddress $RemoteVPNBGPPeerIP -PeerASN 65501 -Name AzureNVA2

Start-Sleep 10 

Get-VpnS2SInterface
Get-BgpPeer

Stop-Transcript
