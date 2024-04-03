# Network Restricted Azure Functions 

## Features of this deployment
- Azure Functions configuration:
    - Authentication to Azure Storage using Managed Identity
    - Authentication to Event Hub using Managed Identity
    - Authentication to Key Vault using Managed Identity
    - Connects to Storage, Event Hub, and Key Vault over Private Endpoints
    - VNET Integrated to control outbound traffic
    - Inbound traffic over Private endpoints
    - Key Vault references work by using Entra ID authentication, and over private endpoints
- Storage Account
    - Configured with Private Endpoints
    - Configured for Entra ID authentication and RBAC
    - Encryption with Customer Managed Key
    - Connection to Key Vault using the "Trusted Azure Services" feature
- Event Hub
    - Configured with Private Endpoints
    - Configured for Entra ID authentication and RBAC
    - Connection From Azure Monitor using the "Trusted Azure Services" feature
- Key Vault
    - Configured with Private Endpoints
    - Configured for Entra ID authentication and RBAC
