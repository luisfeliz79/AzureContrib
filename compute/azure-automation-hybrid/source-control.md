# Automation-Runbooks


## Configuration pre-steps
- Configure a System assigned or User Assigned managed identity
- Assign Contributor role to the identity for the Automation account
- If using UAMI, create a variable called AUTOMATION_SC_USER_ASSIGNED_IDENTITY_ID with the App ID of the UAMI
- Create a PAT for Github

##### Minimum PAT permissions for GitHub

The following table defines the minimum PAT permissions required for GitHub. For more information about creating a PAT in GitHub, see [Create a personal access token for the command line](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/).

|Scope  |Description  |
|---------|---------|
|**`repo`**     |         |
|`repo:status`     | Access commit status         |
|`repo_deployment`      | Access deployment status         |
|`public_repo`     | Access public repositories         |
|`repo:invite` | Access repository invitations |
|`security_events` | Read and write security events |
|**`admin:repo_hook`**     |         |
|`write:repo_hook`     | Write repository hooks         |
|`read:repo_hook`|Read repository hooks|


# To see a sample repository, go here:
- https://github.com/luisfeliz79/automation-runbooks

Reference
- https://learn.microsoft.com/en-us/azure/automation/source-control-integration
  
