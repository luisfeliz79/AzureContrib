param($LocalBGPIP,$RemoteVPNIP, $RemoteVPNBGPPeerIP,$BgpCustomRoute,$SharedSecret)


$BGPRouterID=$LocalBGPIP
$BGPLocalASN="65502"

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
Add-BgpRouter -BgpIdentifier   $BGPRouterID -LocalASN $BGPLocalASN 
Add-BgpCustomRoute -Network $BgpCustomRoute

#Configure VPN BGP Peer
Add-BgpPeer   -LocalIPAddress  $BGPRouterID  -PeerIPAddress $RemoteVPNBGPPeerIP -PeerASN 65501 -Name AzureNVA1

# Add test app to host file
"10.230.1.4      rslabprivateapp.azurewebsites.net"  |Out-File -Encoding ascii  -Append -FilePath C:\windows\system32\drivers\etc\hosts

# Add test file to local web server
"Greetings from $($ENV:COMPUTERNAME)"  |Out-File -Encoding ascii  -FilePath C:\inetpub\wwwroot\index.html

Set-Service RaMgmtSvc -StartupType Automatic
Set-Service RemoteAccess -StartupType Automatic


Start-Sleep 10 
Get-VpnS2SInterface
Get-BgpPeer
Get-BgpRouteInformation

Stop-Transcript
