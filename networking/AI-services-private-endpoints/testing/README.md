# Quickly Test the policies using using Terraform.
This plan will create an AI Services instance and a set of cognitive service accounts in Azure. Then it will configure private endpoints without the DNS integration.

## To use it, follow these steps:

1. Update the locals block in `locals.tf` with your Azure subscription ID, deployment region and a prefix to avoid name collisions.

    ```hcl
    // locals.tf

    locals {
        prefix          = "<yourname>" # Max 9 characters, example luisfeliz
        region          = "eastus2"    # example eastus2
        subscription_id = "<your subscription id>"
    }

    ```
2. Run the following commands in your terminal:

    ```bash
    terraform init
    terraform plan -out my.plan
    terraform apply "my.plan"
    ```

3. After the resources are created, you can check the Azure portal to see the AI Services instance and the cognitive service accounts.
    - Confirm the DeployIfNotExist policies have been applied.  The easiest way to do this is to check the Resource Group > Deployments section.
    - Once the policies have been applied:
        - Check the Private endpoints created for each service
        - Validate the DNS configuration for the private endpoints.

4. To clean up the resources, run:
    ```bash
    terraform destroy --auto-approve
    ```