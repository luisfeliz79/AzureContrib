
# data "azurerm_kubernetes_cluster" "createdAksCluster" {
#   name                = "rslabaks"
#   resource_group_name = azurerm_resource_group.spoke_rg.name
#   depends_on = [
#     azurerm_kubernetes_cluster.aksapp
#   ]
# }

# provider "kubernetes" {

#   host = "https://${azurerm_kubernetes_cluster.aksapp.fqdn}"

#   client_certificate = data.azurerm_kubernetes_cluster.createdAksCluster.kube_config.client_certificate
#   client_key         = data.azurerm_kubernetes_cluster.createdAksCluster.kube_config.client_key
#   cluster_ca_certificate = data.azurerm_kubernetes_cluster.createdAksCluster.kube_config.cluster_ca_certificate
#   #cluster_ca_certificate = azurerm_kubernetes_cluster.aksapp.conf
# }

provider "kubernetes" {

  host = "https://${azurerm_kubernetes_cluster.aksapp.fqdn}"

  #client_certificate = azurerm_kubernetes_cluster.aksapp.kube_config.client_certificate
  #client_key         = azurerm_kubernetes_cluster.aksapp.kube_config.client_key
  #cluster_ca_certificate = azurerm_kubernetes_cluster.aksapp.kube_config.cluster_ca_certificate
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aksapp.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aksapp.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aksapp.kube_config.0.cluster_ca_certificate)
  #cluster_ca_certificate = azurerm_kubernetes_cluster.aksapp.conf
}


#-----------------------------------------
# KUBERNETES DEPLOYMENT COLOR APP
#-----------------------------------------
resource "kubernetes_deployment" "netcheck" {
    metadata {
        name = "netcheck"
        labels = {
            app   = "netcheck"
        } //labels
    } //metadata
    
    spec {
        selector {
            match_labels = {
                app   = "netcheck"                
            } //match_labels
        } //selector
        #Number of replicas
        replicas = 1
        #Template for the creation of the pod
        template { 
            metadata {
                labels = {
                    app   = "netcheck"
                } //labels
            } //metadata

            spec {
                container {
                    image = "luisfeliz79/netcheck"   #Docker image name
                    name  = "netcheck"          #Name of the container specified as a DNS_LABEL. Each container in a pod must have a unique name (DNS_LABEL).
                                      
                    #List of ports to expose from the container.
                    port { 
                        container_port = 80
                    }//port          
                    
                    resources {
                    } //resources
                } //container
            } //spec
        } //template
    } //spec
} //resource
















#-------------------------------------------------
# KUBERNETES DEPLOYMENT COLOR SERVICE NODE PORT
#-------------------------------------------------
# resource "kubernetes_service" "color-service-np" {
#   metadata {
#     name = "color-service-np"
#   } //metadata
#   spec {
#     selector = {
#       app = "color"
#     } //selector
#     session_affinity = "ClientIP"
#     port {
#       port      = 8080 
#       node_port = 30085
#     } //port
#     type = "NodePort"
#   } //spec
# } //resource