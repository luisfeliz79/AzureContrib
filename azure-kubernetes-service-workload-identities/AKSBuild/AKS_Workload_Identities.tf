#  Notes, ensure AKS has workload identities enabled
#  using these attributes:
#  
#  oidc_issuer_enabled         = true
#  workload_identity_enabled   = true
#
#


# Create the User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "uaid1" {
  location            = local.location
  name                = "${local.cluster_name}-workid1"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the Kubernetes Service account
resource "kubernetes_service_account" "servaccount1" {
  metadata {
    name = "workid1"
    annotations = {
        "azure.workload.identity/client-id" = "${azurerm_user_assigned_identity.uaid1.client_id}"


    }
    labels = {
        "azure.workload.identity/use" = "true"
    }
    
  }
  secret {
    name = "${kubernetes_secret.servaccount_secret.metadata.0.name}"
  }
}

resource "kubernetes_secret" "servaccount_secret" {
  metadata {
    name = "workid1-secret"
  }
}

#Create the federated identity
resource "azurerm_federated_identity_credential" "fedid1" {
  name                = "workdid1-fedid"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aksapp.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.uaid1.id
  subject             = "system:serviceaccount:${kubernetes_service_account.servaccount1.metadata[0].namespace}:${kubernetes_service_account.servaccount1.metadata[0].name}"

}


output _AKS_OIDC_URL {
    value = azurerm_kubernetes_cluster.aksapp.oidc_issuer_url
}

output _AKS_service_account_name {
    value = "${kubernetes_service_account.servaccount1.metadata[0].namespace}/${kubernetes_service_account.servaccount1.metadata[0].name}"
}
output _managed_identity_id {
    value = azurerm_user_assigned_identity.uaid1.id
}
output _managed_identity_client_id {
    value = azurerm_user_assigned_identity.uaid1.client_id
}

