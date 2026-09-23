# Summary of Required Permissions

| Identity | Permission required |
|---|---|
| Entra ID user installing the Microsoft Graph Change Tracking service principal | One of: **Application Administrator**, **Cloud Application Administrator**, or **Global Administrator** |
| Microsoft Graph Change Tracking service principal (`0bf30f3b-4a52-48df-9a82-234910c4a086`) | **Azure Event Hubs Data Sender** on the destination Event Hub |
| Client identity consuming notifications | **Azure Event Hubs Data Receiver** on the destination Event Hub |
| Event Hubs namespace managed identity (system-assigned or user-assigned) using a customer-managed key | With the Key Vault RBAC model: **Key Vault Crypto Service Encryption User**. With the Key Vault access-policy model: key permissions **Get**, **List**, **Wrap Key**, and **Unwrap Key** |
| Azure resources deployment service principal | **Key Vault Contributor** for Key Vault deployment; **Key Vault Administrator** to create keys, secrets, or certificates; **Azure Event Hubs Data Owner** for Event Hubs; **Storage Account Contributor** for storage-account deployment; **Storage Blob Data Contributor** to create blob containers |
| Microsoft Graph notification administration service principal | Microsoft Graph application permissions **Mail.Read** and **Calendars.Read**; for Exchange Application RBAC, scoped roles **Application Mail.Read** and **Application Calendars.Read** |
| Entra ID user configuring Exchange Application RBAC | **Exchange Administrator** |