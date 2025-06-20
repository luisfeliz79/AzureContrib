
#!/bin/bash


# This script allows each VM or VMSS Instance configure itself for monitoring
# Ideally, we should have this script kick off an automation function to handle
# the Extension and DCR modifications to avoid having to give it permissions
# For now, it will handle it directly

# Requires:
#
# 1) A User Assigned Managed Identity to be assigned, and with the following permissions
#   - Monitoring Contributor
#   - Log Analytics Contributor
#   - Virtual Machine Contributor (to install AMA on the VMSS instances and VMs)
# 2) The Azure CLI utility required to be installed
#    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# 3) The Azure Monitor Agent extension to be installed ()
#    Done by the this script for VMSS instances

# V1.0.0
#Configure the User Assigned Managed Identity Resource ID
msiId="/subscriptions/xxxxxx/resourcegroups/xxxxx/providers/microsoft.managedidentity/userassignedidentities/azure-monitor-enable"

#Configure the ID of the DCR
ruleId="/subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Insights/dataCollectionRules/syslogs-eventhub"

#Configure the IDs of the DCEs
declare -A regional_dces
regional_dces["eastus2"]="/subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Insights/dataCollectionEndpoints/eastus2dce"
regional_dces["eastus"]="/subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Insights/dataCollectionEndpoints/eastusdce"
regional_dces["centralus"]="/subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Insights/dataCollectionEndpoints/centralusdce"

#Configure the AMA Version
#See this https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-extension-versions
amaVersion="1.28"

# SCRIPT START
echo "[$(date)] Azure Monitor Agent DCR/DCE Association Script"

# Authenticate
az login --identity -u $msiId --allow-no-subscriptions

# Notes, Azure CLI can be installed via the following commmand:
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
if [ $? -ne 0 ]; then
    echo "============== ERROR ======================"
    echo "At [$(date)] "
    echo "Failed to login to Azure CLI"
    echo "  Check to see if the MSI is assigned to the VM"
    echo "  Check if the Azure CLI utility is installed"
    echo "==========================================="  
    exit 1
else 
    echo "[$(date)] Logged into Azure CLI"
fi


# Gather VM information via IMDS
echo "[$(date)] Gathering VM information via IMDS"
imdsMetadata=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01")

# Use an available JSON Parser to parse the IMDS response
jqExists=$(whereis -b jq | awk '{print $2}')
python3Exists=$(whereis -b python3 | awk '{print $2}')
pythonExists=$(whereis -b python | awk '{print $2}')

if [[ "$jqExists" != "" ]]; then
echo "jq exists at $jqExists"
resourceId=$(echo $imdsMetadata | jq -r .resourceId)
VmName=$(echo $imdsMetadata | jq -r .name)
VmLocation=$(echo $imdsMetadata |jq -r .location)

elif [[ "$python3Exists" != "" ]]; then
echo "python3 exists at $python3Exists"
resourceId=$(echo $imdsMetadata | python3 -c "import json, sys; print(json.loads(sys.stdin.read())['resourceId'])")
VmName=$(echo $imdsMetadata | python3 -c "import json, sys; print(json.loads(sys.stdin.read())['name'])")
VmLocation=$(echo $imdsMetadata | python3 -c "import json, sys; print(json.loads(sys.stdin.read())['location'])")

elif [[ "$pythonExists" != "" ]]; then
echo "python exists at $pythonExists"
resourceId=$(echo $imdsMetadata | python -c "import json, sys; print(json.loads(sys.stdin.read())['resourceId'])")
VmName=$(echo $imdsMetadata | python -c "import json, sys; print(json.loads(sys.stdin.read())['name'])")
VmLocation=$(echo $imdsMetadata | python -c "import json, sys; print(json.loads(sys.stdin.read())['location'])")
fi
echo   "[$(date)] ResourceId: $resourceId"
echo   "[$(date)] Name: $VmName"
echo   "[$(date)] Location: $VmLocation"

# Set the Endpoint Id based on the location
EndpointId=${regional_dces[$VmLocation]}
echo "[$(date)] Selected EndpointId: $EndpointId"

# Split the msiId into an array
declare -a msiIdArray
for x in $(IFS='/';echo $msiId); do
    msiIdArray+=($x);
done
msiName=${msiIdArray[-1]}

# Split the ResourceId into an array
declare -a idArray
for x in $(IFS='/';echo $resourceId); do
    idArray+=($x);
done

# Check to see if this a VMSS instance
if [[ "${idArray[-4]}" = "virtualMachineScaleSets" ]]; then
echo "[$(date)] VMSS Instance detected";
isVmss=true;

# Infer the VMSS resource Id (first 8 elements of the array)
vmId=$(for i in {0..7}; do echo -n "/${idArray[i]}"; done)
vmssName=${idArray[-3]}
vmssRg=${idArray[-7]}

# Install the Azure Monitor Extension for a virtual machine scale set instance
# This will happen for each instance individually
echo "[$(date)] Installing or Updating the Azure Monitor Agent Extension"
updateMeUrl="https://management.azure.com"$resourceId"/extensions/AzureMonitorLinuxAgent?api-version=2023-07-01"
#  vmExtensionPayload='{"properties":{"autoUpgradeMinorVersion":true,"enableAutomaticUpgrade":true,"publisher": "Microsoft.Azure.Monitor","settings": "{authentication:{managedIdentity:{identifier-name:'$msiName',identifier-value:'$msiId'}}}","type": "AzureMonitorLinuxAgent","typeHandlerVersion": "1.28"}}'
vmExtensionPayload='{"location":"'$VmLocation'","properties":{"autoUpgradeMinorVersion":false,"enableAutomaticUpgrade":false,"publisher": "Microsoft.Azure.Monitor","settings": { "authentication":{"managedIdentity":{"identifier-name":"mi_res_id","identifier-value":"'$msiId'"}}},"type": "AzureMonitorLinuxAgent","typeHandlerVersion": "'$amaVersion'"}}'
echo $updateMeUrl
echo $vmExtensionPayload

az rest --method PUT -u "$updateMeUrl" --body "$vmExtensionPayload"

if [[ "${idArray[-1]}" = "0" ]];  then
    echo "[$(date)] This is the first instance! thefore, will associate DCR/DCEs"
else
    echo "[$(date)] This is not the first instance, therefore exiting at this point !"
    exit 0;
fi
fi 

# Check to see if this is a traditional VM
if [[ ${idArray[-2]} = "virtualMachines" ]] && ! [[ $isVmss = true ]] ;
then
echo "[$(date)] Virtual Machine detected";
vmId=$resourceId

# Install the Azure Monitor Extension for a virtual machine
echo "[$(date)] Installing or Updating the Azure Monitor Agent Extension"
updateMeUrl="https://management.azure.com"$resourceId"/extensions/AzureMonitorLinuxAgent?api-version=2023-07-01"
vmExtensionPayload='{"location":"'$VmLocation'","properties":{"autoUpgradeMinorVersion":false,"enableAutomaticUpgrade":false,"publisher": "Microsoft.Azure.Monitor","settings": { "authentication":{"managedIdentity":{"identifier-name":"mi_res_id","identifier-value":"'$msiId'"}}},"type": "AzureMonitorLinuxAgent","typeHandlerVersion": "'$amaVersion'"}}'


echo $updateMeUrl
echo $vmExtensionPayload
az rest --method PUT -u "$updateMeUrl" --body "$vmExtensionPayload"



fi 

echo "[$(date)] Using this resourceId: $vmId"

if [[ -z $vmId ]]; then
echo "[$(date)] Unable to determine VM Id"
#exit 1
fi

# If we got here, we are either a regular VM or the first VMSS Instance

echo "[$(date)] Associating DCR"
#Associate the DCR
dcrAssociationName="send-custom-logs-to-storage-account"
dcrAssociationUrl="https://management.azure.com"$vmId"/providers/Microsoft.Insights/dataCollectionRuleAssociations/"$dcrAssociationName"?api-version=2022-06-01"
dcrPayload='{"properties":{"dataCollectionRuleId":"'$ruleId'"}}'
az rest --method PUT -u "$dcrAssociationUrl" --body $dcrPayload

echo "[$(date)] Associating DCE"
#Associate the DCE
dceAssociationName="configurationAccessEndpoint"
dceAssociationUrl="https://management.azure.com"$vmId"/providers/Microsoft.Insights/dataCollectionRuleAssociations/"$dceAssociationName"?api-version=2022-06-01"
dcePayload='{"properties":{"dataCollectionEndpointId":"'$EndpointId'"}}'
az rest --method PUT -u "$dceAssociationUrl" --body $dcePayload

echo "[$(date)] Done associating DCR/DCEs"




