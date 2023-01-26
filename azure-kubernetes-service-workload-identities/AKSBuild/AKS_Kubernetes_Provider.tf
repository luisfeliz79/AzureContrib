provider "kubernetes" {

  host = "https://${azurerm_kubernetes_cluster.aksapp.fqdn}"

  client_certificate     = base64decode(azurerm_kubernetes_cluster.aksapp.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aksapp.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aksapp.kube_config.0.cluster_ca_certificate)
}
