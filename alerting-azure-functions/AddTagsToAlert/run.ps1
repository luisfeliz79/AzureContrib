using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)


$ErrorActionPreference="Stop"
$CachePath="/home/site/wwwroot/cache.json"

$currentUTCtime = (Get-Date).ToUniversalTime()
Write-Information "Incoming Alert at $currentUTCtime"


Write-Information "Performing checks ..."

# Obtain the Target Webhook from Environment variables
$TargetWebHook=$ENV:Target_Webhook

if ($TargetWebHook -eq "" -or $null -eq $TargetWebHook) {
  Write-Information "No Target Webhook found, exiting."
  Write-Information "Please add a Configuration setting called Target_Webhook pointing to the https endpoint of the target monitoring system"
  exit
}

if ((Test-Path -Path $CachePath) -ne $true) {
  Write-Information "No Cache file found, exiting."
  Write-Information "Please ensure the GetAllTags function has run successfully at least once before running this function"
  break
}


# We need to convert to json, and then convert to an object
# to create a properly formatted object we can add members to

if ($null -ne $Request.Body) {  
  $AlertBodyJson=$Request.Body | ConvertTo-Json -Depth 99
  $AlertBody = $AlertBodyJson | ConvertFrom-Json
} else {
  Write-Information "No Request Body found"
  $AlertBody = $null
}


if ($null -eq $AlertBody) {
  # If there was no body alert, then log this happened, and quit
  Write-Information "No Alert body found, documenting contents of the request"
  Write-Information $($Request | ConvertTo-Json -Depth 99)
} else {
  # Found an Alert body, go ahead and process it

  try {
    # Get the Resource
    $resourceId=$AlertBody.data.essentials.alertTargetIDs[0]
    Write-Information "ResourceId: $resourceId"

    # Read the cached tag data
    $tags = Get-Content $CachePath | ConvertFrom-Json 

    # Get the tags from the Cached data
    $resourceTags=($tags | Where-Object id -eq $resourceId).tags
    Write-Information "tags:"
    

    # Create an object with all the tags
    if ($null -ne $resourceTags){
       
        Write-Information "Creating tags object ..."
        $tagKeys=($resourceTags | Get-Member -MemberType NoteProperty).Name
        Write-Information "Tag Keys: $($tagKeys -join ', ')"
        $customTags = [PSCustomObject]@{}
        $tagKeys | ForEach-Object {
            $customTags | Add-Member -MemberType NoteProperty -Name $_ -Value $resourceTags.$_ -Force
        }
        Write-Information "Custom Tags:"
        
        # Add it to the payload
        $AlertBody.data | Add-member -MemberType NoteProperty -Name customProperties -value $CustomTags -Force
        Write-Information "Added Custom tags to payload"
        
    }
  } catch {
    Write-Information "There was an error adding tag data, forwarding the alert without changes"
  }

  $payLoad= $AlertBody | ConvertTo-Json -Depth 99
  
  Write-Information "Sending Payload ..."
  $Send_Payload_Result=Invoke-WebRequest -Uri $TargetWebHook -Method Post -Body $payLoad -ContentType 'application/json'
  Write-Information "Result: $($Send_Payload_Result.StatusCode)"
}

# Always return 200 OK
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
  StatusCode = [HttpStatusCode]::OK
  body = $payLoad
})

