#!/bin/bash

# Requires:
#
# 1) A User Assigned Managed Identity to be assigned, and with the following permissions
#   - Monitoring Contributor
#   - Log Analytics Contributor
#   - Virtual Machine Contributor for VMSS only (to enable the VMSS upgrade policy)
# 2) The Azure CLI utility to be installed
# 3) The Azure Monitor Agent extension to be installed ()

#Configure the User Assigned Managed Identity Resource ID
msiId="/subscriptions/xxxxxx/resourcegroups/xxxxx/providers/microsoft.managedidentity/userassignedidentities/azure-monitor-enable"

#Configure the ID of the DCR
ruleId="/subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Insights/dataCollectionRules/syslogs-eventhub"

#Configure the IDs of the DCEs
declare -A regional_dces
regional_dces["eastus2"]="/subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Insights/dataCollectionEndpoints/eastus2dce"
regional_dces["eastus"]="/subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Insights/dataCollectionEndpoints/eastusdce"
regional_dces["centralus"]="/subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Insights/dataCollectionEndpoints/centralusdce"

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
resourceId=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01" | python3 -c "import json, sys; print(json.loads(sys.stdin.read())['resourceId'])")
echo $VmId
VmName=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01" | python3 -c "import json, sys; print(json.loads(sys.stdin.read())['name'])")
echo $VmId
VmLocation=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01" | python3 -c "import json, sys; print(json.loads(sys.stdin.read())['location'])")

echo   "[$(date)] ResourceId: $resourceId"
echo   "[$(date)] Name: $VmName"
echo   "[$(date)] Location: $VmLocation"

# Set the Endpoint Id based on the location
EndpointId=${regional_dces[$VmLocation]}
echo "[$(date)] Selected EndpointId: $EndpointId"


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


  if [[ "${idArray[-1]}" = "0" ]];  then
    echo "[$(date)] This is the first instance!"

    # Set the VMSS upgrade policy to automatic
    echo "[$(date)] Setting the VMSS upgrade policy to automatic"    
    az vmss update --name $vmssName --resource-group $vmssRg --set upgradePolicy.mode=Automatic --no-wait



  else
    echo "[$(date)] This is not the first instance, therefore quitting !"
    exit 0;
  fi
fi 

# Check to see if this is a traditional VM
if [[ ${idArray[-2]} = "virtualMachines" ]] && ! [[ $isVmss = true ]] ;
then
  echo "[$(date)] Virtual Machine detected";
  vmId=$resourceId
fi 

echo "[$(date)] Using this resourceId: $vmId"

if [[ -z $vmId ]]; then
  echo "[$(date)] Unable to determine VM Id"
  #exit 1
fi

echo "[$(date)] Associating DCR"
#Associate the DCR
dcrAssociationName="syslogs-and-metrics-dcr"
dcrAssociationUrl="https://management.azure.com"$vmId"/providers/Microsoft.Insights/dataCollectionRuleAssociations/"$dcrAssociationName"?api-version=2022-06-01"
dcrPayload='{"properties":{"dataCollectionRuleId":"'$ruleId'"}}'
az rest --method PUT --url "$dcrAssociationUrl" --body $dcrPayload

echo "[$(date)] Associating DCE"
#Associate the DCE
dceAssociationName="configurationAccessEndpoint"
dceAssociationUrl="https://management.azure.com"$vmId"/providers/Microsoft.Insights/dataCollectionRuleAssociations/"$dceAssociationName"?api-version=2022-06-01"
dcePayload='{"properties":{"dataCollectionEndpointId":"'$EndpointId'"}}'
az rest --method PUT --url "$dceAssociationUrl" --body $dcePayload

echo "[$(date)] Done associating DCR/DCEs"
