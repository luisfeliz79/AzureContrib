#!/bin/bash

apimResourceId="/subscriptions/fc4f8971-77b0-47e6-a975-e183b16794cb/resourceGroups/APIM-trusted-services/providers/Microsoft.ApiManagement/service/lufeliz-apim-trusttest"
restCall="https://management.azure.com$apimResourceId?api-version=2024-05-01"

# Get the current properties of the APIM instance
az rest --method GET --url $restCall --query "properties.customProperties" > current-properties.json
echo "==================================="
echo " WARNING: This script will apply custom settings to API Management"
echo "          During this process, momentary downtime is expected. Please run this script during a maintenance window."
echo "==================================="
echo "CURRENT SETTINGS:"
cat current-properties.json
echo "==================================="

# pause and wait for user input before proceeding
read -p "Press enter to continue or CTRL+C to cancel"

# Insert the new property to disable over-privileged access for managed identities
jq '. += {"Microsoft.WindowsAzure.ApiManagement.Gateway.ManagedIdentity.DisableOverPrivilegedAccess": "true"}' current-properties.json > updated-properties-1.json
jq '{customProperties: .}' updated-properties-1.json > updated-properties-2.json
jq '{properties: .}' updated-properties-2.json > updated-properties-final.json

echo "==================================="
echo "SETTINGS to be APPLIED:"
cat updated-properties-final.json
echo "==================================="

# pause and wait for user input before proceeding
read -p "Press enter to continue or CTRL+C to cancel"

az rest --method PATCH --uri $restCall --body @updated-properties-final.json

rm updated-properties-1.json updated-properties-2.json

echo "==================================="
echo "SETTINGS APPLIED, please wait a few minutes for the operation to complete"
echo "You can check 'status' in the portal, by going here:"
echo "https://portal.azure.com/#resource$apimResourceId/overview"
echo "==================================="




