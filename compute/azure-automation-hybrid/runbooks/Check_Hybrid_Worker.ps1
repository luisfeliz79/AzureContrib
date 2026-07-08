# Sample outputs
#   Write-host "This is what Write-host looks like"
#   Write-warning "This is what Write-warning looks like"
#   Write-error "This is what Write-error looks like"
# These do not show in the Jobs status area
#   Write-Information "This is a Write-Information"
#   Write-Verbose "This is a Write-Verbose"

# This is a sample PowerShell 7.2 Runbook
# meant to provide some basic checks and information
# for a Hybrid worker based on the Azure Connected Machine agent.

# Begin report
Write-host "Running: hostname =========="
Write-host "Hello from $(hostname) at $(Get-Date)"

Write-host "`nRunning: PowerShell Version =========="
Write-host  "PowerShell Version Info $($psversiontable.psversion | convertto-json)"

Write-host "`nRunning: Proxy Settings =========="
Write-host "Proxy Settings`n HTTP_PROXY: $($ENV:HTTP_PROXY) `n HTTPS_PROXY: $($ENV:HTTPS_PROXY)"

Write-host "`nRunning: azcmagent check =========="
$out=azcmagent check
$out

Write-host "`nRunning: azcmagent show =========="
$out=azcmagent show
$out

Write-host "`nRunning: systeminfo =========="
$out=systeminfo
$out
Write-host "======= COMPLETE =============="


