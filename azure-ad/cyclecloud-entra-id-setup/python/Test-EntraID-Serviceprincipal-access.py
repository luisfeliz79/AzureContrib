#  pip install msal

import msal

#########################
# USER SETTINGS
#########################
client_id="<CLIENT-ID>"
thumbprint="<CERTIFICATE THUMBPRINT>"
private_key_file="./certificate-file.pem"
tenant_id="<tenant name, ex contoso.onmicrosoft.com"
scopes=["<Application ID URI for the Cyclecloud Entra ID integration application, ex:   api://032648dd-3abb-403b-8fc6-732c534db882/.default>"]

#####################


#########################
# Script code
#########################

authority="https://login.microsoftonline.com/"+tenant_id
pemFileContents = open(private_key_file, 'r').read()
global_token_cache = msal.TokenCache()
client_credentials = {
                    "thumbprint": thumbprint,
                    "private_key": pemFileContents
                    }


global_app = msal.ConfidentialClientApplication(
    client_credential=client_credentials,
    client_id=client_id,
    authority=authority,
    token_cache=global_token_cache
    )

result = global_app.acquire_token_for_client(scopes=scopes)

if "access_token" in result:
    print(result["access_token"])
    print("")
    print("Token acquisition succeeded")
else:
    print("Token acquisition failed", result,result["error_description"])

