output GETTING_STARTED {
    value = "\n    Install and Configure kubectl tools by using these commands:\n       az aks install-cli\n       az aks get-credentials --name ${local.cluster_name} --resource-group ${local.rg_name}\n\n    To access the storage account via the portal, you will need to white list your EXTERNAL IP on the firewall:\n       az storage account network-rule add --resource-group ${local.rg_name} --account-name ${azurerm_storage_account.sa.name} --ip-address x.x.x.x"  
}

