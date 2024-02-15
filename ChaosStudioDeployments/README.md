# Create a VNET with the 2 required Chaos Studio subnets
# It outputs the two Subnet Resource IDs
az deployment group create --resource-group newchaos \
               --template-file .\ChaosStudioDeployVnetInjectionSubnets.json \
               --parameters virtualNetworkName=chaos-studio-vnet

# Onboards a Key Vault instance with the VNET Injection settings to Chaos Studio
az deployment group create --resource-group newchaos \
               --template-file .\OnboardKeyVaultWithVnetInjection.json \
               --parameters \
                 KeyVaultInstanceName=lufeliztargetkv \ 
                 containerSubnetId="/subscriptions/e31e07c8-2d2c-4c74-9886-e6f7d80c9646/resourceGroups/newchaos/providers/Microsoft.Network/virtualNetworks/chaos-studio-vnet/subnets/ChaosStudioContainerSubnet" \
                 relaySubnetId="/subscriptions/e31e07c8-2d2c-4c74-9886-e6f7d80c9646/resourceGroups/newchaos/providers/Microsoft.Network/virtualNetworks/chaos-studio-vnet/subnets/ChaosStudioRelaySubnet"

# Onboards a Network Security Group to Chaos Studio
az deployment group create --resource-group newchaos \
              --template-file .\OnboardNetworkSecurityGroup.json \
              --parameters NSGResourceId="/subscriptions/e31e07c8-2d2c-4c74-9886-e6f7d80c9646/resourceGroups/newchaos/providers/Microsoft.Network/networkSecurityGroups/target-networksecgroup"

# Onboards a Service Bus to Chaos Studio
az deployment group create --resource-group newchaos \
              --template-file .\OnboardServiceBus.json \
              --parameters ServiceBusResourceId="/subscriptions/e31e07c8-2d2c-4c74-9886-e6f7d80c9646/resourceGroups/newchaos/providers/Microsoft.ServiceBus/namespaces/lufelizservicebus333"