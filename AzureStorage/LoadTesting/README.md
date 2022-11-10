# JavaBlobTest
A Java app that reads and lists blobs on Azure Blob Storage

## How to use
 - Create and prepare a storage account
 - Configure options
 - Run the program

&nbsp;
## Prepare the storage account
1) Create a storage account and configure with desired features and settings
2) Create a container in the storage account, ex testdata
3) Upload 1 or more files to this container
4) Add your "human" account to RBAC permissions or a Managed Identity) Add your "human" account to RBAC permissions or a Managed Identity
Use roles "Storage Blob Reader" or "Storage Blob Contributor"

&nbsp;
## Configuration
### There are the configuration options

| Name          | Purpose                    |
| ----------------- | -------------------------------- |
| storageBlobEndpoint | Https URL of the storage account blob endpoint               |
| containerName | The container name in the storage account. Default: testdata                | 
| numberOfDownloads | The GetBlob operation will run this many times. Default: 10                | 

  
### The options can be configured via

- Using configuration file
  
  > Create a json file called javablob.config with this contents, and adjusting as needed

  ```json
  {
    "containerName":  "testdata",
    "storageBlobEndpoint":  "https://<SANAME>.blob.core.windows.net/",
    "numberOfDownloads":  10
  }
  ```
 
- Using environment variables

  ```bash
  # For Linux
  export storageBlobEndpoint = "https://<SANAME>.blob.core.windows.net/"
  export numberOfDownloads = "10"
  export containerName = "testdata"

  # For Windows
  $env:storageBlobEndpoint = "https://<SANAME>.blob.core.windows.net/"
  $env:numberOfDownloads = "10"
  $env:containerName = "testdata"
  ```
&nbsp;
## Run the program
- Run it locally on a development machine

  ```bash
  Note: Requires Java runtime, Maven, Azure CLI

  cd source/javablob
  mvn compile
  mvn package
  mvn install dependency:copy-dependencies

  # Authenticate first using Azure CLI
  
  # This account should have "Storage Blob reader" or "Storage Blob Contributor" permissions to the storage account

  az login

  # Run the Java program
  # For Windows
  java -cp "target/javablob-1.0-SNAPSHOT.jar;target/dependency/*" com.felizlabs.SingleThreadApp

  # For Linux
  java -cp "target/javablob-1.0-SNAPSHOT.jar:target/dependency/*" com.felizlabs.SingleThreadApp
  ```
- Run it as a docker container
  > Note if you wish to create your own container, see [here](docker)
  ```bash
  
  Note: Requires one of the following
  * Azure Virtual machine
  * Azure Arc enabled Virtual Machine
  * Azure Container Instances
  * Azure Container Apps
  * Azure App Service
  * Azure Spring Apps
         --- and ---
  * Enable the Managed Identity

  DockerHub: luisfeliz79/javablobtest:latest
    
  # Example for virtual machine:
  sudo docker run luisfeliz79/javablobtest &

- Run it on Azure Kubernetes service

  > Note: The AKS Cluster must have either [Pod Identities](https://learn.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity) or [Workload Identies](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview) enabled

  Sample Yaml configuration file:
  * Update the storageBlobEndpoint value
  * Update the serviceAccountName or aadpodidbinding value for the Managed Identity
  * Update the image if using your own container registry/image

  
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: javablob
    namespace: javablob
  # For Pod Identities
  # labels:
  #   aadpodidbinding: msi-podidentity-name
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: javablob
    template:
      metadata:
        labels:
          app: javablob
      spec:
        nodeSelector:
          kubernetes.io/os: linux
        # For Workload Identities
        # serviceAccountName: msi-serviceaccount-name
        containers:
          - name: javablob
            image: luisfeliz79/javablobtest:latest
            imagePullPolicy: IfNotPresent
            env:
            - name: storageBlobEndpoint
              value: "https://<storageaccount>.blob.core.windows.net/"
            - name: numberOfDownloads
              value: "20"
  ```
