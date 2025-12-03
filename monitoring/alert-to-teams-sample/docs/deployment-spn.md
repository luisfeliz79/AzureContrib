## Deployment SPN requirements

- Simple Setup:
    - Contributor and User Access Administrator at the subscription level

- Least Privilege Setup:
    - Assumptions: Providers are already registered
    Resource Group already exists with at least reader access

    - Roles
        - App Service Environment Contributor
        - Log Analytics Contributor
        - Monitoring Contributor
        - Logic Apps Standard Contributor (Preview)
        - Managed Identity Contributor
        - Managed Identity Operator
        - Network Contributor
        - Storage Account Contributor
        - Web Plan Contributor
        - Website Contributor

- For RBAC Assignments
    - Option 1) provide role at the RG level for "User Access Administrator"
    - Option 2) Configure these manually for the User assigned managed identity:
   
        | Role Name                          | Scope                                      |
        |-----------------------------------|--------------------------------------------|
        Monitoring Metrics Publisher | App Insights resource                     |
        | Storage Table Data Contributor      | Storage Account resource                  |
        | Storage Queue Data Contributor      | Storage Account resource                  | 
        | Storage Account Contributor        | Storage Account resource                  |















