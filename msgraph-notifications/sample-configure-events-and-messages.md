# Sample subscription creation for Events and Messages

```bash
#Example

$EventHubNamespace="lufelizmsgraph"
$EventHubName="graph_notify"
$TenantName="MngEnvMCAP917066.onmicrosoft.com"
$SpnAppId="44e7a205-5262-4ccd-b273-3aa788847204"
$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile("./mycert.pem")

$encCert=$(get-content "./myenccert.pem" -Raw) -replace "-----BEGIN CERTIFICATE-----" -replace "-----END CERTIFICATE-----" -replace "`n"

 

Install-Module Microsoft.Graph.ChangeNotifications
Import-Module Microsoft.Graph.ChangeNotifications

Connect-MgGraph  -TenantId $TenantName -ClientId $SpnAppId -certificate $Cert






$UserIds="da49083c-1e08-47d0-ae6c-a374f3d2b04a","902664d7-4f86-4926-8f9f-96779e926b76","e077e599-ab8a-4102-90f5-9ff37ee772d9"

$Resources=@()
$UserIds | ForEach {

	$Resources+="/users/$_/messages?$('$select')=Subject,bodyPreview,importance,receivedDateTime,from"
	$Resources+="/users/$_/events?$('$select')=Subject,bodyPreview,importance,organizer"

}

$Resources


$changeType="created"



# Define Notification URL and other parameters for the subscription

$notificationUrl = [string]::Format('EventHub:https://{0}.servicebus.windows.net/eventhubname/{1}?tenantId={2}', $EventHubNamespace, $EventHubName, $TenantName)

$notificationUrl

$resources | foreach {

	$expirationTime=[System.DateTime]::UtcNow.AddMinutes(10070)
	$expirationTime=[System.DateTime]::UtcNow.AddMinutes(10)
	
	# Create Payload

	$params = @{
	    changeType = $changeType
	    notificationUrl = $notificationUrl
	    resource = $_
	    expirationDateTime = $expirationTime
	    includeResourceData = "true"
	    encryptionCertificate = $encCert
	    encryptionCertificateId = "mycert"
	    
	}
	$params

	New-MgSubscription -BodyParameter $params
}

get-MgSubscription | select ApplicationId,resource,ExpirationDateTIme,NotificationUrl

# for cleaning up
#Get-MgSubscription | foreach {Remove-MgSubscription -subscriptionid $_.id}

#Max number of subscriptions? - limit 10K, https://learn.microsoft.com/en-us/graph/api/resources/change-notifications-api-overview?view=graph-rest-1.0

# Lifetime is 10,070 for non-rich, 1440 for rich -> https://learn.microsoft.com/en-us/graph/api/resources/subscription?view=graph-rest-1.0#subscription-lifetime:~:text=10%2C080%20minutes%20(under%20seven%20days)

#does it have to be recreated ?


# A maximum of 1,000 active subscriptions per mailbox for all applications is allowed.


```