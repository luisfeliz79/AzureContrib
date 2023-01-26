#Prereqs
$ErrorActionPreference="SilentlyContinue"
$LogPath = 'C:\WindowsAzure\Logs\RSLABBuild.log'
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $LogPath -append

Install-WindowsFeature -Name Web-Server -IncludeManagementTools
"Greetings from $($ENV:COMPUTERNAME)"  |Out-File -Encoding ascii  -FilePath C:\inetpub\wwwroot\index.html


Stop-Transcript
