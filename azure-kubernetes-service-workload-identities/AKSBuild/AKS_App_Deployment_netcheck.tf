

# Deploy netcheck app
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
                annotations = {

                    //  for Workload Identities Sidecar
                    "azure.workload.identity/inject-proxy-sidecar" = "true"
                    "azure.workload.identity/proxy-sidecar-port"   = "8080"

                    // If we specify /use = true on the Pod template, the pods need to successfully
                    // get a managed identity assigned to be successful
                    // to change this behavior, remove this line or comment it out
                    "azure.workload.identity/use" = "true"
        
                } // annotations
 



            } //metadata

            spec {
                // for workload identities
                service_account_name = "${kubernetes_service_account.servaccount1.metadata[0].name}"

                container {
                    image = "luisfeliz79/netcheck"   #Docker image name
                    name  = "netcheck"               #Name of the container specified as a DNS_LABEL. Each container in a pod must have a unique name (DNS_LABEL).
                                      
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