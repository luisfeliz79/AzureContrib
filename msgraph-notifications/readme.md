# WORK IN PROGRESS
# Deploy procedure for Graph Notifications with Event Hub

## Pre-work

### Microsoft Graph Change Tracking SP Installation
This step involves installing the required service principal for Microsoft Graph Change tracking, on to your tenant.  This is SP will be used to authenticate/authorize the Microsoft graph service to the target Event Hub

```powershell
# 1) login with a Entra ID account that has one of the following roles: Application Administrator,  Cloud Application Administrator, or Global Administrator
az login --tenant <your-tenant-id>

# 2) Add the service principal to the tenant
# Note: 0bf30f3b-4a52-48df-9a82-234910c4a086 is the well known ID for the Microsoft Graph Change Tracking service
az ad sp create --id 0bf30f3b-4a52-48df-9a82-234910c4a086


# 3) Get the Object ID of the service principal
az ad sp show --id 0bf30f3b-4a52-48df-9a82-234910c4a086 --query id --output tsv

```

### Event Hub

1. Create an Event Hub namespace 
2. Create an Event Hub within the namespace, ex. `graph_notify`
3. Add RBAC role "Azure Event Hubs Data Sender" for the `object id` of the Microsoft Graph Change Tracking SP, you can search by oid or by display name
4. Collect these pieces of information:
	- EventHub Namespace name
	- Eventhub Name
	- Tenant Name


### Configure Graph Notifications with Event Hub

```powershell
#Example

$EventHubNamespace="<your-event-hub-namespace>"
$EventHubName="<your-event-hub-name>"
$TenantName="<your-tenant-name>"
$SpnAppId="<your-spn-app-id>"
$SpnCertificatePath="<your-spn-certificate-path>"

$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile($SpnCertificatePath)

$encCert=$(get-content $SpnCertificatePath -Raw) -replace "-----BEGIN CERTIFICATE-----" -replace "-----END CERTIFICATE-----" -replace "`n"

# Install and Loaded needed modules
Install-Module Microsoft.Graph.ChangeNotifications
Import-Module Microsoft.Graph.ChangeNotifications

# Connect to Microsoft Graph using the service principal and certificate
Connect-MgGraph  -TenantId $TenantName -ClientId $SpnAppId -certificate $Cert

# Sample list of IDs
$UserIds="da49083c-1e08-47d0-ae6c-a374f3d2b04a","902664d7-4f86-4926-8f9f-96779e926b76","e077e599-ab8a-4102-90f5-9ff37ee772d9"

$Resources=@()
$UserIds | ForEach {

	$Resources+="/users/$_/messages"
	$Resources+="/users/$_/events"

}

# Show the payload for learning purposes
$Resources

# This must be set to created
$changeType="created"


# Define Notification URL and other parameters for the subscription
$notificationUrl = [string]::Format('EventHub:https://{0}.servicebus.windows.net/eventhubname/{1}?tenantId={2}', $EventHubNamespace, $EventHubName, $TenantName)

$notificationUrl

$resources | foreach {

    # This defines the subscription lifetime, please observe maximums
	$expirationTime=[System.DateTime]::UtcNow.AddMinutes(10070)
	
    #For testing renewal
    #$expirationTime=[System.DateTime]::UtcNow.AddMinutes(10)
	
	# Create Payload

	$params = @{
	    changeType = $changeType
	    notificationUrl = $notificationUrl
	    resource = $_
	    expirationDateTime = $expirationTime	    
	}
	$params

	New-MgSubscription -BodyParameter $params
}

# For listing Existing subscriptions
# Get-MgSubscription | select ApplicationId,resource,ExpirationDateTIme,NotificationUrl

# For Renewal
#Get-MgSubscription | foreach { 
#	 Write-host "Updating $($_.id)"
#	 $newTime=[System.DateTime]::UtcNow.AddMinutes(10070)
#	 Update-MgSubscription -SubscriptionId $_.id -ExpirationDateTime $newTime
#}



# For cleaning up all subscriptions
# Get-MgSubscription | foreach {Remove-MgSubscription -subscriptionid $_.id}



# Lifetime is 10,070 for non-rich, 1440 for rich -> https://learn.microsoft.com/en-us/graph/api/resources/subscription?view=graph-rest-1.0#subscription-lifetime:~:text=10%2C080%20minutes%20(under%20seven%20days)


```