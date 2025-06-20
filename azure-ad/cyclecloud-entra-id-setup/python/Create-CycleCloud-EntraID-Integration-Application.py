# Python module install instructions
#     python -m venv entraid
#     ./entraid/bin/activate           # Bash
#     .\entraid\Scripts\activate.ps1   # PowerShell
#     python -m pip install msgraph-sdk azure-identity
#     modify the script with the correct values - line 92
#     python app.py

# Expected Environment varaibles
# AZURE_TENANT_ID: ID of the service principal's tenant. Also called its 'directory' ID.
# AZURE_CLIENT_ID: the service principal's client ID
# AZURE_CLIENT_CERTIFICATE_PATH: path to a PEM or PKCS12 certificate file including the private key.
# AZURE_CLIENT_CERTIFICATE_PASSWORD: (optional) password of the certificate file, if any.
# AZURE_CLIENT_SEND_CERTIFICATE_CHAIN: (optional) If True, the credential will send the public certificate chain in the x5c header of each token request's JWT. This is required for Subject Name/Issuer (SNI)

#$env:AZURE_TENANT_ID="5d441269-2b3b-4905-9103-101379592c8d"
#$env:AZURE_CLIENT_ID="aab3f379-3dbd-4e31-81e2-6b3ccf50c833"
#$env:AZURE_CLIENT_CERTIFICATE_PATH="C:\Users\lufeliz\OneDrive\certs\sp-mgmt\sp-mgmt.pem"


# to update
# include assignment requirement = yes
# ask for app reg name and also cyclecloud url
# and add a single page app
# and add a redirect uri
# add user app role

from msgraph import GraphServiceClient
from msgraph.generated.models.application import Application
from msgraph.generated.models.service_principal import ServicePrincipal
from msgraph.generated.models.app_role import AppRole
from msgraph.generated.models.api_application import ApiApplication
from msgraph.generated.models.permission_scope import PermissionScope
from azure.identity.aio import DefaultAzureCredential
import asyncio
import uuid
import time

#####################################################
#  Get an Entra ID Application
###################################################### 
# https://learn.microsoft.com/en-us/graph/api/application-get?view=graph-rest-1.0&tabs=python
def get_application(object_id=None,graph_client=None):
    if (object_id):
      result = graph_client.applications.by_application_id(object_id).get()
      return result
    else:
       print ("No App found")
       return None


#####################################################
#  Create an Entra ID Application
###################################################### 
# https://learn.microsoft.com/en-us/graph/api/application-post-applications?view=graph-rest-1.0&tabs=http
def create_application(request_body=None,graph_client=None):
    if (request_body):        
        result = graph_client.applications.post(request_body)
        return result
    else:
       print ("No request_body was specified")

#####################################################
#  Update an Entra ID Application
###################################################### 
# https://learn.microsoft.com/en-us/graph/api/application-update?view=graph-rest-1.0&tabs=python
def update_application(object_id=None,request_body=None,graph_client=None):
    if (object_id):
        if (request_body):
            result = graph_client.applications.by_application_id(object_id).patch(request_body)
            return result
        else:
            print ("No request_body was specified")
    else:
        print ("No App Id Specified")
#####################################################
#  Create an Entra ID Service Principal
###################################################### 
# https://learn.microsoft.com/en-us/graph/api/serviceprincipal-post-serviceprincipals?view=graph-rest-1.0&tabs=http
def create_service_principal(request_body=None,graph_client=None):
    if (request_body):        
        result = graph_client.service_principals.post(request_body)
        return result
    else:
       print ("No request_body was specified")



# ###########################################################
# #
# #                        MAIN
# #
# ###########################################################

async def main():
    print ("Starting ...")

    credential = DefaultAzureCredential()
    scopes =  scopes = ['https://graph.microsoft.com/.default']
    graph_client = GraphServiceClient(credential, scopes)

    print ("Creating the App ...")

    # ###########################################################
    # Creating an application
    # ###########################################################    
    
    # Define the properties
    # https://learn.microsoft.com/en-us/graph/api/application-update?view=graph-rest-1.0&tabs=python
    newApp=Application(
        display_name = "Cyclecloud-EntraID-Integration",
        description = "Created by script -- Cyclecloud EntraID Integration",
        sign_in_audience = "AzureADMyOrg",
    )

    returned=await create_application(request_body=newApp,graph_client=graph_client)

    # ###########################################################
    # Grab the appId and Id of the new App
    # ###########################################################
    object_id = str(returned.id)
    app_id = str(returned.app_id)
    display_name = str(returned.display_name)
    identifierUri = "api://"+app_id

    print("Details of newly created application")
    print("===================================")
    print("DisplayName  : ",display_name)
    print("ObjectId     : ",object_id)
    print("AppID        : ",app_id)
    print("IdentifierUri: ",identifierUri)
    print("===================================")

    # ###########################################################
    # Now update some settings
    # ###########################################################
    
    updateApp = Application(
    identifier_uris=[
        identifierUri
    ],

    app_roles = [
            AppRole(
                allowed_member_types = [
                    "User","Application",
                ],
                description = "Global.Node.User",
                display_name = "Global.Node.User",
                is_enabled = True,
                value = "Global.Node.User",
                id = str(uuid.uuid4())
            ),
            AppRole(
                allowed_member_types = [
                    "User","Application",
                ],
                description = "Global.Node.Admin",
                display_name = "Global.Node.Admin",
                is_enabled = True,
                value = "Global.Node.Admin",
                id = str(uuid.uuid4())
            ),
            AppRole(
                allowed_member_types = [
                    "User","Application",
                ],
                description = "Cluster.Creator",
                display_name = "Cluster.Creator",
                is_enabled = True,
                value = "ClusterCreator",
                id = str(uuid.uuid4())
            ),
            AppRole(
                allowed_member_types = [
                    "User","Application",
                ],
                description = "Administrator",
                display_name = "Administrator",
                is_enabled = True,
                value = "Administrator",
                id = str(uuid.uuid4())
            ),
            AppRole(
                allowed_member_types = [
                    "User","Application",
                ],
                description = "SuperUser",
                display_name = "SuperUser",
                is_enabled = True,
                value = "SuperUser",
                id = str(uuid.uuid4())
            ),
    ],

    api = ApiApplication(

        oauth2_permission_scopes = [
            PermissionScope (            
                admin_consent_description = "user_access",
                admin_consent_display_name = "user_access",
                id = str(uuid.uuid4()),
                is_enabled = True,
                type = "User",
                user_consent_description = "user_access",
                user_consent_display_name = "user_access",
                value = "user_access"           
            )
        ]



    )


    )

    print ("Waiting 15 seconds for the new application to sync....")
    time.sleep(15)

    print ("Updating Application settings...")
    returned=await update_application(object_id=object_id,request_body=updateApp,graph_client=graph_client)
    print ("Updated Application settings")

   # ###########################################################
   # Now create the matching service principal
   # ###########################################################
 
    createServicePrincipal = ServicePrincipal(
        app_id = app_id
    )

    print ("Waiting 15 seconds for the new updates to sync....")
    time.sleep(15)
    print ("Creating Service principal...")
    returned=await create_service_principal(request_body=createServicePrincipal,graph_client=graph_client)
    print ("Created Service principal")

    print ("Complete")

    # ###########################################################
    # Getting an application -- just a sample
    # ###########################################################
    # print(await get_application(object_id=object_id,graph_client=graph_client))


# ###########################################################
# Run main when the script is executed
# ###########################################################
if __name__ == "__main__":
    asyncio.run(main())
