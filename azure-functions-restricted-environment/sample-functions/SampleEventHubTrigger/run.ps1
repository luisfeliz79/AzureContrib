param($eventHubMessages, $TriggerMetadata)

Write-Host "Incoming Event Hub Event"

$eventHubMessages | ConvertTo-Json