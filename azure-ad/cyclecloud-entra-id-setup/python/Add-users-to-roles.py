# Python module install instructions
#     python -m venv entraid
#     ./entraid/bin/activate       # Bash
#     .\entraid\Scripts\activate   # PowerShell
#     python -m pip install msgraph-sdk azure-identity
#     modify the script with the correct values - line 92
#     python app.py

# Expected Environment variables
# AZURE_TENANT_ID: ID of the service principal's tenant. Also called its 'directory' ID.
# AZURE_CLIENT_ID: the service principal's client ID
# AZURE_CLIENT_CERTIFICATE_PATH: path to a PEM or PKCS12 certificate file including the private key.
#
# AZURE_CLIENT_CERTIFICATE_PASSWORD: (optional) password of the certificate file, if any.
# AZURE_CLIENT_SEND_CERTIFICATE_CHAIN: (optional) If True, the credential will send the public certificate chain in the x5c header of each token request's JWT. This is required for Subject Name/Issuer (SNI)

# from msgraph import GraphServiceClient
# from msgraph.generated.models.application import Application
# from msgraph.generated.models.service_principal import ServicePrincipal
# from msgraph.generated.models.app_role import AppRole
# from msgraph.generated.models.api_application import ApiApplication
# from msgraph.generated.models.permission_scope import PermissionScope
# from azure.identity.aio import DefaultAzureCredential
# import asyncio
# import uuid
# import time

# Code snippets are only available for the latest version. Current version is 1.x
from msgraph import GraphServiceClient
from msgraph.generated.models.app_role_assignment import AppRoleAssignment
from azure.identity.aio import DefaultAzureCredential
import asyncio
from uuid import UUID

# To initialize your graph_client, see https://learn.microsoft.com/en-us/graph/sdks/create-client?from=snippets&tabs=python

async def add_user_role(user_id,principal_id, resource_id, app_role_id):
    request_body = AppRoleAssignment(
        principal_id = UUID("cde330e5-2150-4c11-9c5b-14bfdc948c79"),
        resource_id = UUID("8e881353-1735-45af-af21-ee1344582a4d"),
        app_role_id = UUID("00000000-0000-0000-0000-000000000000"),
    )

    result = await graph_client.users.by_user_id(user_id).app_role_assignments.post(request_body)
    return result

async def remove_user_role(user_id,app_role_assignment_id):
    result = await graph_client.users.by_user_id(user_id).app_role_assignments.by_app_role_assignment_id(app_role_assignment_id).delete()
    return result

async def get_user_role(user_id,graph_client):
    result = await graph_client.users.by_user_id(user_id).get()
    return result


async def main():
    print ("Starting ...")

    credential = DefaultAzureCredential()
    scopes =  scopes = ['https://graph.microsoft.com/.default']
    graph_client = GraphServiceClient(credential, scopes)

    user_id = "da49083c-1e08-47d0-ae6c-a374f3d2b04a"

    print(await get_user_role(user_id,graph_client))

if __name__ == "__main__":
    asyncio.run(main())
