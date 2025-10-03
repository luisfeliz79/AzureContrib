[cmdletbinding()] 
param(

    [Switch]$CheckAll

)

Function GetSchannelProtocolStatus ($Protocol) {

    $Status = @{
        "Client"="NotSet"
        "Server"="NotSet"
    }

    $Values=Get-ChildItem -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Recurse -ErrorAction SilentlyContinue | % {Get-ItemProperty -Path Registry::$($_.Name) }

    Switch ($Values.PSChildName) {
        "Client" { 
                If ($Values.DisabledByDefault -eq 0) {$Status.Client="EnabledByDefault-"}
                if ($Values.DisabledByDefault -eq 1) {$Status.Client="DisabledByDefault-"}
                if ($Values.Enabled -eq 1) { $Status.Client+="Enabled"}
                if ($Values.Enabled -eq 0) { $Status.Client+="Disabled"}

                                
         }
        "Server" { 
                If ($Values.DisabledByDefault -eq 0) {$Status.Server="EnabledByDefault-"}
                if ($Values.DisabledByDefault -eq 1) {$Status.Server="DisabledByDefault-"}
                if ($Values.Enabled -eq 1) { $Status.Server+="Enabled"}
                if ($Values.Enabled -eq 0) { $Status.Server+="Disabled"}

        }
    }

    $Status #Return Status

}

Function GetStrongCrypto  {

param(

    [Parameter()] [ValidateSet("v4.0.30319",'v2.0.50727')] $Version,
    [Parameter()] [ValidateSet('32bit','64bit','Both')] $Architecture
)

    $Status = "NotSet"
    $Key=$(if($Architecture -eq "32bit"){"SOFTWARE\Wow6432Node"} else {"SOFTWARE"})

    $Values=Get-ItemProperty -Path "Registry::HKLM\$Key\Microsoft\.NETFramework\$Version" -ErrorAction SilentlyContinue
    If ($Values.SchUseStrongCrypto -eq 1) { $Status="Enabled"}
    if ($Values.SchUseStrongCrypto -eq 0) { $Status="Disabled"}
    $Status

}

Function GetWinHTTPDefault  {

param(

    [Parameter()] [ValidateSet('32bit','64bit','Both')] $Architecture
)


    $Key=$(if($Architecture -eq "32bit"){"SOFTWARE\Wow6432Node"} else {"SOFTWARE"})

    $Values=Get-ItemProperty -Path "Registry::HKLM\$Key\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" -ErrorAction SilentlyContinue
    
    if ($Values.DefaultSecureProtocols) {$Values.DefaultSecureProtocols} else {"NotSet"}

}



function CheckAllSettings () {

$oarray += new-object PSObject -property ([ordered]@{

 #Select-XML allows you to address XML elements as they appear on the file
 "ReportTime" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
 "ComputerName" = $env:ComputerName 

  "SSL20-Client"  =(GetSchannelProtocolStatus -Protocol "SSL 2.0").Client
  "SSL20-Server"  =(GetSchannelProtocolStatus -Protocol "SSL 2.0").Server

 "SSL30-Client"  =(GetSchannelProtocolStatus -Protocol "SSL 3.0").Client
  "SSL30-Server"  =(GetSchannelProtocolStatus -Protocol "SSL 3.0").Server

 "TLS10-Client" =(GetSchannelProtocolStatus -Protocol "TLS 1.0").Client
  "TLS10-Server" =(GetSchannelProtocolStatus -Protocol "TLS 1.0").Server 

  "TLS11-Client"      =(GetSchannelProtocolStatus -Protocol "TLS 1.1").Client
  "TLS11-Server"      =(GetSchannelProtocolStatus -Protocol "TLS 1.1").Server

  "TLS12-Client"      =(GetSchannelProtocolStatus -Protocol "TLS 1.2").Client
  "TLS12-Server"      =(GetSchannelProtocolStatus -Protocol "TLS 1.2").Server

  "TLS13-Client"      =(GetSchannelProtocolStatus -Protocol "TLS 1.3").Client
  "TLS13-Server"      =(GetSchannelProtocolStatus -Protocol "TLS 1.3").Server


  "NET40-64"      =(GetStrongCrypto -Version "v4.0.30319" -Architecture "64bit")
  "NET40-32"      =(GetStrongCrypto -Version "v4.0.30319" -Architecture "32bit")
  "NET20-64"      =(GetStrongCrypto -Version "v2.0.50727" -Architecture "64bit")
  "NET20-32"      =(GetStrongCrypto -Version "v2.0.50727" -Architecture "32bit")

  "WINHTTP-64"    =(GetWinHTTPDefault -Architecture "64bit")
  "WINHTTP-32"    =(GetWinHTTPDefault -Architecture "32bit")

}) #new-object

$oarray


# create a powershell object out of the data below
$TLSDefaultData=@()

$TLSDefaultData+=[PSCustomObject]@{
    "OS"="Windows Server 2016"
    "SSLv2"="Not Supported"
    "SSLv3"="Disabled"
    "TLS 1.0"="Enabled"
    "TLS 1.1"="Enabled"
    "TLS 1.2"="Enabled"
    "TLS 1.3"="Not Supported"
}
$TLSDefaultData+=[PSCustomObject]@{
    "OS"="Windows Server 2019"
    "SSLv2"="Not Supported"
    "SSLv3"="Disabled"
    "TLS 1.0"="Enabled"
    "TLS 1.1"="Enabled"
    "TLS 1.2"="Enabled"
    "TLS 1.3"="Not Supported"
}
$TLSDefaultData+=[PSCustomObject]@{
    "OS"="Windows Server 2019"
    "SSLv2"="Not Supported"
    "SSLv3"="Disabled"
    "TLS 1.0"="Disabled"
    "TLS 1.1"="Disabled"
    "TLS 1.2"="Enabled"
    "TLS 1.3"="Not Supported"
}
$TLSDefaultData+=[PSCustomObject]@{
    "OS"="Windows Server 2022"
    "SSLv2"="Not Supported"
    "SSLv3"="Disabled"
    "TLS 1.0"="Disabled"
    "TLS 1.1"="Disabled"
    "TLS 1.2"="Enabled"
    "TLS 1.3"="Enabled"
}

Write-host "This Operating System is "  -ForegroundColor Magenta
$((Get-CimInstance Win32_OperatingSystem).Caption)

Write-host "`nDefault TLS settings by Windows Version" -ForegroundColor Magenta
write-host "NotSet means that the setting is not configured and the OS default applies" -ForegroundColor DarkGray
$TLSDefaultData | Format-Table | Out-String | Write-Host

Write-host "REF:"
Write-host "https://learn.microsoft.com/en-us/security/engineering/solving-tls1-problem#figure-1-security-protocol-support-by-os-version"
break



#https://docs.microsoft.com/en-us/windows/desktop/SecAuthN/protocols-in-tls-ssl--schannel-ssp-
}

CheckAllSettings



