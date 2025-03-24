# Required Setup
#   Add a VM or VMSS instance with Managed Identity (preferably with a User assigned identity)
#   Create Azure Storage Account and Container
#       RBAC: VM or VMSS Managed identity -> Storage Blob Data Contributor on the Storage account 
#       Private Endpoints config or Storage account account Firewall setup to allow traffic from the VM or VMSS
#   Azure CLI installed on the VM or VMSS
#   Docker installed on the VM or VMSS
#   Fluent Bit Docker image pulled or available for download (ex fluent/fluent-bit)

# Install Azure CLI
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Docker
# https://docs.docker.com/engine/install/ubuntu/
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

