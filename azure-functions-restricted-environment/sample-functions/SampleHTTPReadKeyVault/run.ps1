using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Only run if environment variable $env:VAULT_NAME
if ($env:VAULT_NAME -ne $null) {
    Write-host "Reading the secret..."
    $Secret = Get-AzKeyVaultSecret -VaultName $env:VAULT_NAME -Name "Test" -AsPlainText 
    $body = "The secret has been read successfully from vault: $($env:VAULT_NAME), here was the response: ($Secret)"
} else {
    Write-host "The VAULT_NAME variable was not found"
    $body = "The VAULT_NAME variable was not found"
}


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
