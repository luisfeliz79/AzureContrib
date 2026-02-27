# Configure trusted service connectivity in API Management gateway using Azure CLI

This article is based on the [Azure API Management documentation](https://learn.microsoft.com/en-us/azure/api-management/breaking-changes/trusted-service-connectivity-retirement-march-2026#step-3-disable-trusted-service-connectivity-in-api-management-gateway) 

## Introduction
You can use the Azure CLI to disable trusted service connectivity in your API Management gateway. This is a step you can take to ensure your API management is not using the Trusted services signal when connecting to backend services, ahead of the upcoming retirement.

## Things to know before you start
- Updating the API Management configuration will cause momentary outages, so it's recommended to perform this action during a maintenance window.
- To update the setting properly, any other existing custom properties should be included, otherwise they will be removed.


## Steps to disable trusted service connectivity in API Management gateway using Azure CLI

1. Open your terminal and log in to your Azure account using the following command:
    ```bash
    az login
        #or
    az login --use-device-code

    # if prompted to select a subscription, select any subscription.

    ```

2. **Download and Review the sample script** named [set-DisableOverPrivilegedAccess-true.sh](./set-DisableOverPrivilegedAccess-true.sh) and modify the `apimResourceId` variable to include the resource Id of your API management resource. The resource Id should be in the following format:

    ```bash
    apimResourceId="subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}"
    ```

3. Run the script to disable trusted service connectivity in your API Management gateway.

    ```bash
    chmod +x set-DisableOverPrivilegedAccess-true.sh
    ./set-DisableOverPrivilegedAccess-true.sh
    ```


## Re-enabling Trusted services connectivity in API Management gateway using Azure CLI
A similar script is provided to re-enable trusted service connectivity in your API Management gateway if needed. Review the sample script named [set-DisableOverPrivilegedAccess-false.sh](./set-DisableOverPrivilegedAccess-false.sh) 

and modify the `apimResourceId` variable to include the resource Id of your API management resource. Then run the script to re-enable trusted service connectivity in your API Management gateway.




