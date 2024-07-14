# Azure Storage SDK for Java - Blob Storage - Sample

## Pre-requisites
- Create a storage account (Standard or Premium) in Azure
- Create a container in the storage account
- Configure RBAC permissions as specified in the [Azure Storage RBAC documentation](https://docs.microsoft.com/en-us/azure/storage/common/storage-auth-aad-rbac-portal)


## Configure the sample
- Update these two lines with the storage account and container information
```java
    // Specify the storage account name and container name 
    String accountName = "<the storage account name (not the fqdn)>";
    String container = "<the name of a container>";
```


## Authentication using [DefaultAzureCredential](https://learn.microsoft.com/en-us/java/api/overview/azure/identity-readme?view=azure-java-stable#environment-variables)

### If using Service Principal

- If you have previously used az login, ensure to log out first, using az logout
- Configure the environment variables
```bash
# For Bash / Linux
export AZURE_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export AZURE_TENANT_ID="xxxxx.onmicrosoft.com or 00000000-0000-0000-0000-000000000000"
export AZURE_CLIENT_CERTIFICATE_PATH="/path/to/certificate.pem"

# For PowerShell / Windows (or Linux)
$env:AZURE_CLIENT_ID="00000000-0000-0000-0000-000000000000"
$env:AZURE_TENANT_ID="xxxxx.onmicrosoft.com or 00000000-0000-0000-0000-000000000000"
$env:AZURE_CLIENT_CERTIFICATE_PATH="C:\Azure\sp-cert.pem"
```
Make sure to add permisions such as "Storage Blob Data Contributor" to the Service principal
- Then run the sample



### If using Managed Identity (System Assigned)
- Enable the system assigned managed identity in the Azure service
- Make sure to add permisions such as "Storage Blob Data Contributor" to the managed identity
- Then run the sample



### If using Managed Identity (User Assigned)

- Uncomment and Update this line in the sample to include the UA Managed Identity APPID

```java
    // Specify the Client ID of the user assigned managed identity
    DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()
        .managedIdentityClientId("<MANAGED_IDENTITY_CLIENT_ID aka APPID>")
        .build();
```

- ... and comment out the existing DefaultAzureCredential line
```java
    // DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder().build();
```
- Make sure to add permisions such as "Storage Blob Data Contributor" to the managed identity
- Then run the sample

### For authenticating with the Logged in user
- Login interactively as the user using the Azure CLI

```bash
az login
```
- Make sure to add permisions such as "Storage Blob Data Contributor" to the managed identity
- Then run the sample


## Compiling and running the sample

```
cd java\javablob
mvn clean package assembly:single
java -jar .\target\javablob-1.0-SNAPSHOT-jar-with-dependencies.jar
```

## Azure SDK For Java Libraries used in the sample (Maven)

### For Dependency management
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.azure</groupId>
            <artifactId>azure-sdk-bom</artifactId>
            <version>--enter a version, such as 1.2.24--</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

### For Azure Identity functions
```xml
    <dependency>
        <groupId>com.azure</groupId>
        <artifactId>azure-identity</artifactId>
    </dependency>
```

### For Azure Storage blob service
```xml
    <dependency>
        <groupId>com.azure</groupId>
        <artifactId>azure-storage-blob</artifactId>
    </dependency>

    <dependency>
        <groupId>com.azure</groupId>
        <artifactId>azure-storage-common</artifactId>
    </dependency>
```


