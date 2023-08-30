# Sample - Storage Account Table service access via AAD Authentication

This sample demonstrates how to use Azure Active Directory (AAD) authentication to access Azure Storage Table service.

## Prerequisites

### RBAC Permissions

Storage Table Data Contributor permissions are required for the service principal used to run this sample:
![Permissions required](/images/Storage%20Account%20Table%20RBAC.png)

### Authentication
Configure environment variables for the AAD authentication - Service principal

- Using a service principal with a secret

```bash
AZURE_TENANT_ID="<change-me>"
AZURE_CLIENT_ID="<change-me>"
AZURE_CLIENT_SECRET='<change-me>'
```

- Using a service principal with a certificate
```bash
AZURE_TENANT_ID="<change-me>"
AZURE_CLIENT_ID="<change-me>"
AZURE_CLIENT_CERTIFICATE_PATH="/path/to/pfxOrPem" #	A path to certificate and private key pair in PEM or PFX format, which can authenticate the App Registration.
AZURE_CLIENT_CERTIFICATE_PASSWORD="<change-me>"     #	(Optional) The password protecting the certificate file (currently only supported for PFX (PKCS12) certificates).
AZURE_CLIENT_SEND_CERTIFICATE_CHAIN="true or 1"	# (Optional) Specifies whether an authentication request will include an x5c header to support subject name / issuer based authentication. When set to `true` or `1`, authentication requests include the x5c header.
```

### Storage Account Name
Set the Storage account name varialble

```bash
STORAGE_ACCOUNT_NAME="<change-me>"
```

## Running the sample

```bash

# NOTE: Set required environment variables as documented above

cd demo
mvn clean package
java -jar ".\target\demo-1.0-SNAPSHOT-jar-with-dependencies.jar"
```