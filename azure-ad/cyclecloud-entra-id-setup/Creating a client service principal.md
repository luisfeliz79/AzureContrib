# Creating a service principal for automated cyclecloud access

## Steps
In the Azure Portal > Entra ID > App registrations

-   Create a new App registration
    - Enter a name for the App registration   
    - Select the supported account types (Accounts in this organizational directory only)
    - Do not enter a redirect URI

Locate and access the new App registration
-   Configure the API permissions
    - Under API Permissions, click on Add a permission
    - Click on APIs my organization uses
    - Search for the name of the App registration created for Cyclecloud Entra ID Integration (ex. Cyclecloud-EntraID-Integration)
    - Select the App registration
    - Click on Application permissions
    - Choose the desired permissions
    - Click on Add permissions
    - Grant Admin consent (required)

- Configure service principal credentials
    - Under Certificates & secrets, click on the Certificates tab > Upload certificate
    - Select a PEM file that contains the public portion of a certificate
    - Enter a description for the certificate

- Collect details
    - Under Overview, note down the Application (client) ID
    - Under Certificates & secrets, note down the Thumbprint and the Certificate (public key)


If you wish to test the new client service principal, use [this python script](./python/Test-EntraID-Serviceprincipal-access.py)