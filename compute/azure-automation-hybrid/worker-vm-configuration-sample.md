# Configuring a Worker VM - Sample walkthrough

## Things you will need:

- Install Azure PowerShell module (Az) on your administrative machine.  See here: https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-12.0.0

- Create a service principal and certificate for Arc onboarding.  See here: https://learn.microsoft.com/en-us/entra/identity-platform/howto-authenticate-service-principal-powershell

- Configured the needed RBAC Permissions as shown in [azure-rbac-roles.md](./azure-rbac-roles.md)

- The following information for the service principal you created:
  - Application (client) ID
  - Tenant ID
  - Subscription ID
  - Path to the certificate file

- The Azure Arc Gateway Resource Id.

- The Automation Account automationHybridServiceUrl.  This can be found in the Azure Portal, under the Automation Account, in the Overview blade, in JSON View.


## Prep the Windows machine

- ### Configure Proxy settings 
```
# If your proxy address is 192.168.1.1:3128

########################################
# First set the SYSTEM LEVEL PROXY
########################################
  # Simple setup
  netsh winhttp set proxy 192.168.1.1:3128 "<local>"

  # --or-- Advanced setup
  netsh winhttp set proxy proxy-server="http=192.168.1.1:3128;https=192.168.1.1:3128" bypass-list="<local>;*.another.com"

####################################################################
# Now configure Proxy variables for Powershell and other programs
####################################################################

[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://192.168.1.1:3128", "Machine")

[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://192.168.1.1:3128", "Machine")


# To confirm (requires reopening shell or server reboot)
Write-host "HTTP_PROXY: $($ENV:HTTP_PROXY)"
Write-host "HTTPS_PROXY: $($ENV:HTTPS_PROXY)"

# if you need to remove
# [System.Environment]::SetEnvironmentVariable("HTTP_PROXY", $null, "Machine")
# [System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "Machine")

```

- ### Install root cert for proxy
If using a private CA, The proxy's root cert should be part of the Windows Local Machine trusted root certs location

- ### Install PowerShell, and  modules you may need
See here:
https://learn.microsoft.com/en-us/azure/automation/automation-runbook-types?tabs=lps74%2Cpy10

**Luis's Opinion**: Latest versions could/should work also, however, if you run into issues Microsoft support may ask you to use of the supported versions listed in the document as resolution.
	

## Deploy the ARC Agent
The following section uses the script provided by the Azure Portal, with with modification:  Instead of using a Service Principal secret, we are using a Service Principal certificate for better security.

The script also assumes the following:
- A forward proxy is being used for communications to public endpoints
- An Azure Arc Proxy has been deployed and will be used for Arc Agent communications
- For authentication, a service principal with certificate credentails will be used

```

$global:scriptPath = $myinvocation.mycommand.definition

function Restart-AsAdmin {
    $pwshCommand = "powershell"
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $pwshCommand = "pwsh"
    }

    try {
        Write-Host "This script requires administrator permissions to install the Azure Connected Machine Agent. Attempting to restart script with elevated permissions..."
        $arguments = "-NoExit -Command `"& '$scriptPath'`""
        Start-Process $pwshCommand -Verb runAs -ArgumentList $arguments
        exit 0
    } catch {
        throw "Failed to elevate permissions. Please run this script as Administrator."
    }
}

try {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        if ([System.Environment]::UserInteractive) {
            Restart-AsAdmin
        } else {
            throw "This script requires administrator permissions to install the Azure Connected Machine Agent. Please run this script as Administrator."
        }
}
    #################################
    # Configure these details
    #################################
    # Add the service principal application ID and secret here
    $ServicePrincipalId="<Service-Principal-Client-Id>";
    
    #$ServicePrincipalClientSecret="This has been commented out and will not be used";
    
    $ServicePrincipalCert="C:\Folder\Path\To\Cert\cert.pem";

    $env:SUBSCRIPTION_ID = "<Subscription-Id>";
    $env:RESOURCE_GROUP = "<Resource-Group-Name>";
    $env:TENANT_ID = "<Tenant-Id>";
    $env:LOCATION = "<Location>";
    $env:AUTH_TYPE = "principal";
    $env:CORRELATION_ID = "<A random Correlation-Id, ex a7a20bdb-e1dc-4570-84da-28e0e2b7c05f for log tracing>";
    
    $env:CLOUD = "AzureCloud";
    
    $env:GATEWAY_ID = "/subscriptions/<Subscription-Id>/resourceGroups/<Resource-Group-Name>/providers/Microsoft.HybridCompute/gateways/<Gateway-Name>";

    $ProxyServer = "http://192.168.1.1:3128"

    #################################
    # Begin work
    #################################

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072;

    $azcmagentPath = Join-Path $env:SystemRoot "AzureConnectedMachineAgent"
    if (-Not (Test-Path -Path $azcmagentPath)) {
        New-Item -Path $azcmagentPath -ItemType Directory
        Write-Output "Directory '$azcmagentPath' created"
    }

    $tempPath = Join-Path $azcmagentPath "temp"
    if (-Not (Test-Path -Path $tempPath)) {
        New-Item -Path $tempPath -ItemType Directory
        Write-Output "Directory '$tempPath' created"
    }

    $installScriptPath = Join-Path $tempPath "install_windows_azcmagent.ps1"

    # Download the installation package
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/azcmagent-windows" -TimeoutSec 30 -OutFile "$installScriptPath" -proxy $ProxyServer;

    # Install the hybrid agent
    & "$installScriptPath" -proxy $ProxyServer;
    if ($LASTEXITCODE -ne 0) { exit 1; }
    Start-Sleep -Seconds 5;

    # Run connect command
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect --service-principal-id "$ServicePrincipalId" --service-principal-cert "$ServicePrincipalCert" --resource-group "$env:RESOURCE_GROUP" --tenant-id "$env:TENANT_ID" --location "$env:LOCATION" --subscription-id "$env:SUBSCRIPTION_ID" --cloud "$env:CLOUD" --gateway-id "$env:GATEWAY_ID" --tags 'ArcSQLServerExtensionDeployment=Disabled' --enable-automatic-upgrade --correlation-id "$env:CORRELATION_ID";
}
catch {
    $logBody = @{subscriptionId="$env:SUBSCRIPTION_ID";resourceGroup="$env:RESOURCE_GROUP";tenantId="$env:TENANT_ID";location="$env:LOCATION";correlationId="$env:CORRELATION_ID";authType="$env:AUTH_TYPE";operation="onboarding";messageType=$_.FullyQualifiedErrorId;message="$_";};
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/log" -Method "PUT" -Body ($logBody | ConvertTo-Json) -proxy $ProxyServer | out-null;
    Write-Host  -ForegroundColor red $_.Exception;
}

```

## Confirm that you can see the connected Machine in the Azure portal

- Go to
https://portal.azure.com/#servicemenu/Microsoft_Azure_ArcCenterUX/AzureArcCenterHub/servers

- Click on the Machine

- Click on the Json view link on the top right of the machine blade

- Grab the Resource ID.  You will need this for the next section, variable $hwVM



## Create Hybrid Worker group (if  needed)

```
# Details
$workerGroupName       = "<Name of the worker group>"
$automationAccountName = "<name of the automation account>"
$automationAccountRG   = "<name of the resource group>"
$subscription          = "<subscription-id>"

Select-AzSubscription -Subscription $subscription

New-AzAutomationHybridRunbookWorkerGroup -AutomationAccountName $automationAccountName -Name $workerGroupName -ResourceGroupName $automationAccountRG

```

# Add a Hybrid Worker to the group 
```
$hwVM                  = "<Resource-Id-of-the-Connected-Machine>"
$workerGroupName       = "<Name of the worker group>"
$automationAccountName = "<name of the automation account>"
$automationAccountRG   = "<name of the resource group>"
$subscription          = "<subscription-id>"

# Generate a new GUID and pass it as the name of the Hybrid Worker
$hwguid = New-Guid


New-AzAutomationHybridRunbookWorker -Name $hwguid -VmResourceId $hwVM -HybridRunbookWorkerGroupName $workerGroupName -AutomationAccountName $automationAccountName -ResourceGroupName $automationAccountRG
```

## Deploy Automation Extension with proxy settings
```
$settings = @{
    "AutomationAccountURL"  = "<automation-account-url, ex https://(guid).jrds.eus2.azure-automation.net/automationAccounts/(guid)>";    
    "ProxySettings" = @{
        "ProxyServer" = "<proxy-server - in this format 192.168.1.1:3128>";
    }
};


$RG="<resource-group-name>"
$Location="<location>"
$MachineName="<Connected machine name>"
$Subscription="<subscription-id>"

Connect-AzAccount -Tenant "<tenant-id>" -Subscription $Subscription

# For Windows
New-AzConnectedMachineExtension -ResourceGroupName $RG -Location $Location -MachineName $MachineName -Name "HybridWorkerExtension" -Publisher "Microsoft.Azure.Automation.HybridWorker" -ExtensionType HybridWorkerForWindows -TypeHandlerVersion 1.1 -Setting $settings -EnableAutomaticUpgrade
```

## Test a runbook
Finally, test the Hybrid Worker by running a simple runbook on it. 

Here is a sample runbook: [Check_Hybrid_Worker](./runbooks/Check_Hybrid_Worker.ps1)
