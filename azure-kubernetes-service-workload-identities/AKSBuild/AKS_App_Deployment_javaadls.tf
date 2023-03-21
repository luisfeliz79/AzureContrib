# Deploy netcheck app
resource "kubernetes_deployment" "javaadls" {
    metadata {
        name = "javaadls"
        labels = {
            app   = "javaadls"
        } //labels
    } //metadata
    
    spec {
        selector {
            match_labels = {
                app   = "javaadls"                
            } //match_labels
        } //selector
        #Number of replicas
        replicas = 1
        #Template for the creation of the pod
        template { 
            metadata {
                labels = {
                    app   = "javaadls"


                } //labels
                annotations = {

                    //  for Workload Identities Sidecar
                    //  workloads using recent Azure SDK Libraries do not need this
                    // "azure.workload.identity/inject-proxy-sidecar" = "true"
                    // "azure.workload.identity/proxy-sidecar-port"   = "8080"

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
                    image = "luisfeliz79/javaadls"   #Docker image name
                    name  = "javaadls"               #Name of the container specified as a DNS_LABEL. Each container in a pod must have a unique name (DNS_LABEL).
                                      
                    #List of ports to expose from the container.
                    port { 
                        container_port = 80
                    }//port

                    env {
                        name = "JAVAADLS_STORAGEACCT_NAME"
                        value = azurerm_storage_account.sa.name

                    }          
                    
                    resources {
                    } //resources
                } //container
            } //spec
        } //template
    } //spec
} //resource

