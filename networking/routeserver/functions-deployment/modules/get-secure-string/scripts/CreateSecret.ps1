# Create Credentials
$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString
$SecurePassword | ConvertFrom-SecureString | out-file c:\users\lufeliz\acr-creds.sec