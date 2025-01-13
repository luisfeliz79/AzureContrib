import subprocess
import sys
import textwrap
import requests
import json
import uuid
from datetime import datetime
import argparse
import re
import base64
import os.path


# Python module install instructions
#     python -m pip install requests uuid datetime argparse

# For updates, visit
# https://github.com/luisfeliz79/AzureContrib/tree/dev/az-ssh-and-pim



######################################################
#  Decode a JWT token
######################################################
def decode_jwt(token):
  # Split the token into header, payload and signature parts
  header, payload, signature = token.split(".")
  # Decode the payload from base64url to bytes
  payload_bytes = base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4))
  # Decode the bytes to JSON string
  payload_json = payload_bytes.decode("utf-8")
  # Parse the JSON string to a dictionary
  payload_dict = json.loads(payload_json)
  # Return the payload dictionary
  return payload_dict

######################################################
#  Given an access token, return the user's object id
######################################################
def get_user_object_id(token=None):
    if token:        
        decodedAccessToken = decode_jwt(token)
        return decodedAccessToken['oid']

######################################################
#  Given an access token, return the User Principal Name
######################################################
def get_user_upn(token=None):
    if token:
        decodedAccessToken = decode_jwt(token)
        if decodedAccessToken['idtyp'] == 'user':
            return decodedAccessToken['unique_name']
        elif decodedAccessToken['idtyp'] == 'app':
            return decodedAccessToken['appid'] + " (ServicePrincipal)"
        else:
            print ("Invalid token -- cannot proceed.  Try login in with az login")
            exit()
        

######################################################
#  Given an access token, return the amr claims, ex MFA
######################################################
def get_mfa_claims(token=None):
    if token:
        try:
            decodedAccessToken = decode_jwt(token)
            return decodedAccessToken['amr']
        except:
            return ""
        

######################################################
#  Logout any users from the az cli
######################################################       
def logout():

    cmd=([AzCliPath,'logout'])

    if debug:
       print("DEBUG: About to run: ",cmd)
    
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,shell=False)


######################################################
#  Obtain an access token using the az cli
######################################################
def get_access_token():
    cmd=([AzCliPath,'account','get-access-token'])

    if debug:
        print("DEBUG: About to run: ",cmd)

    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,shell=False)

    output = p.stdout.decode()
    err = p.stderr.decode()

    if err:
        # If we got an error, assume we need to login
        return "Error"
        

    if output:
        tokenResult = json.loads(output)
        mfaClaims = get_mfa_claims(tokenResult['accessToken'])
        print(" successful",mfaClaims)
        return tokenResult

######################################################
#  Set the current subscription on AZ CLI
######################################################
def set_current_subscription(subscriptionId=None):
    cmd=([AzCliPath,'account','set','--subscription',subscriptionId])

    if debug:
       print("DEBUG: About to run: ",cmd)
    
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,shell=False)
  
    output = p.stdout.decode()
    err = p.stderr.decode()

    if err:
        # If we got an error, assume we need to login
        print()
        print("Error setting subscription. Check the subscription name or id")
        exit()

######################################################
#  Get the current subscription from AZ CLI
######################################################       
def get_current_subscription():

    cmd=([AzCliPath,'account','show'])

    if debug:
       print("DEBUG: About to run: ",cmd)
    
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,shell=False)

    output = p.stdout.decode()
    err = p.stderr.decode()

    if err:
        # If we got an error, assume we need to login
        print("Error getting subscription")
        exit()

    if output:
        subInfo = json.loads(output)
        return (subInfo["id"],subInfo["name"])        


######################################################
#  login function which checks if user is already logged in
######################################################
def login(tenant=None):

    if reauth:
        # If reauth as specified, then request login
        logout()
        userName = login_picker(tenant)
        return userName

    tokenTest = get_access_token()

    if tokenTest == "Error":        
        # If we got an error, assume we need to login
        userName = login_picker(tenant)
        return userName
    else:
        # Looks like we got a token, lets read the UPN
        # and return it
        token = tokenTest["accessToken"]
        return get_user_upn(token) 
    

######################################################
#  Login using Entra ID Device Code authentication
######################################################
def login_picker(tenant=None):
    if (defaultLoginMethod):
        return login_default_method(tenant)
    else:
        return login_with_device_code(tenant)
    

######################################################
#  Login using Entra ID Device Code authentication
######################################################
def login_with_device_code(tenant=None):
    cmd=([AzCliPath,'login','--use-device-code','--allow-no-subscriptions'])

    if tenant:
            print('Using tenant: ', tenant)
            cmd.append('--tenant')
            cmd.append(tenant)
    if debug:
        print("DEBUG: About to run: ",cmd)

    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=False)
    (output, err) = p.communicate()
    p_status = p.wait()
    
    if err:
        # If we got an error, assume we need to login
        print("Error login in")
        help_for_bad_login()
        exit()

    if output:
        if debug:
            print(output.decode())
        loginResult = json.loads(output)
        return loginResult[0]['user']['name']
    else:
        print ("Error login in")
        help_for_bad_login()
        exit()
    
######################################################
#  Login using Entra ID Default Method
######################################################
def login_default_method(tenant=None):
    cmd=([AzCliPath,'login','--allow-no-subscriptions'])

    if tenant:
            print('Using tenant: ', tenant)
            cmd.append('--tenant')
            cmd.append(tenant)
    if debug:
        print("DEBUG: About to run: ",cmd)

    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=False)
    (output, err) = p.communicate()
    p_status = p.wait()
    
    if err:
        # If we got an error, assume we need to login
        print("Error login in")
        help_for_bad_login()
        exit()

    if output:
        if debug:
            print(output.decode())
        loginResult = json.loads(output)
        return loginResult[0]['user']['name']
    else:
        print ("Error login in")
        help_for_bad_login()
        exit()
    


######################################################
#  Browse schedules dict and find a matching role
######################################################
def find_matching_schedule(roleId=None,scheduleList=None):


    # Loop through the scheduleList and find a matching role
    if scheduleList:
        if roleId:
            for item in scheduleList:
                roleDefinitionId = item["roleDefinitionId"].split('/')[-1]
                if roleDefinitionId == roleId:
                        return item
    
    # If we made it here, return None
    return None

######################################################
#  inspect scheduleList dict and find a matching active role
######################################################
def is_role_already_active(selectedAssignment=None,scheduleList=None):
    if scheduleList:
        if selectedAssignment:
            for item in scheduleList:
                roleDefinitionId = item["roleDefinitionId"].split('/')[-1]
                selectedRoleDefinitionId = selectedAssignment["roleDefinitionId"].split('/')[-1]
                scope = selectedAssignment["scope"]

                if (roleDefinitionId == selectedRoleDefinitionId) and \
                    (item["scope"].lower() == scope.lower()):
                        return True
    
    # if we made it here, return False
    return False
           
######################################################
#  Activate a role assignment schedule using Rest API
######################################################                
def activate_eligible_assignment(token=None,
                                 eligibleAssignment=None,
                                 principalId=None,
                                 justification=None
                                 ):
    # Check for the token
    if not token:
        print("No access token provided")
        return None
    
    if not justification:
        if customPIMJustification:
            justification = customPIMJustification
  
    if eligibleAssignment:

        # API Base Url
        activate_schedule_api_endpoint = "https://management.azure.com"

        # create a random guid name
        uuid_str = str(uuid.uuid4())
        
        # Add the scope
        activate_schedule_api_endpoint += eligibleAssignment["scope"]
                
        # Complete the rest of the url
        activate_schedule_api_endpoint += "/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/"+ uuid_str +"?api-version=2022-04-01-preview"

        # Calculate Start time
        if startTime:
            # convert time passed as parameter and convert to UTC
      
            dt = datetime.fromisoformat(startTime)
            payLoadStartTime = dt.strftime("%Y-%m-%dT%H:%M:%S.%fZ")
        else:
            # Get the current time in UTC format
            dt = datetime.utcnow()
            payLoadStartTime = dt.strftime("%Y-%m-%dT%H:%M:%S.%fZ")


        # Create the payload
        
        payload={}
        payload["properties"] = {}
        payload["properties"]["principalId"] = principalId
        payload["properties"]["roleDefinitionId"] = eligibleAssignment["roleDefinitionId"]
        payload["properties"]["linkedRoleEligibilityScheduleId"] = eligibleAssignment["roleEligibilityScheduleId"]
        payload["properties"]["requestType"] = "SelfActivate"
        payload["properties"]["justification"] = justification
        payload["properties"]["scheduleInfo"] = {}
        payload["properties"]["scheduleInfo"]["startDateTime"] = payLoadStartTime #"2023-07-04T21:31:27.91Z"
        payload["properties"]["scheduleInfo"]["expiration"] = {}
        payload["properties"]["scheduleInfo"]["expiration"]["type"] = "AfterDuration"
        payload["properties"]["scheduleInfo"]["expiration"]["endDateTime"] = None
        payload["properties"]["scheduleInfo"]["expiration"]["duration"] = customPIMDuration
        
        if trace:
            print("TRACE: Url: " + activate_schedule_api_endpoint)
            print("TRACE: Payload: ")
            print(payload)
        
        print("   Scope: ",eligibleAssignment["scope"]) 
        
        result = requests.put(activate_schedule_api_endpoint,
                     json = payload,
                     headers={'Authorization': 'Bearer ' + token},
                     verify=customVerify
                    
                     )

        if (result.status_code >= 200 and result.status_code <= 299):
            if startTime:
                print("   Activation Scheduled for: ",payLoadStartTime, "UTC")
            else:
                print("   Activation Successful")
        else:
            errorStatus=json.loads(result.content)
            if errorStatus["error"]["code"] == "RoleAssignmentExists":
                print("   Activation Successful (RoleAssignmentExists)")
            else:
                print("   Activation Failed")
                print("  ",end="")
                print(result.content)
                exit()
    else:
        print("No eligible assignment provided")
        return None

######################################################
#  Get a list of active schedules/roles using Rest API
###################################################### 
def get_roles_active(token=None,scope=None,subscription=None,resourceGroup=None,managementGroup=None):
    results = ([])

    # If Management group or subscription was passed, add it to the scope
    if managementGroup:
        scope = "/providers/Microsoft.Management/managementGroups/" + managementGroup
    
    if subscription:
        scope = "/subscriptions/" + subscription
        if resourceGroup:
            scope+= "/resourceGroups/" + resourceGroup

    # In all cases, add a trailing slash
    if scope:   
        scope+="/"
    else:
        scope="/"
    # get currently active roles
    active_elegibility_schedule_instances_api_endpoint = "https://management.azure.com" + \
        scope + \
        "providers/Microsoft.Authorization/roleAssignmentSchedules" + \
        "?$filter=asTarget()&api-version=2020-10-01-preview"
    
    url = active_elegibility_schedule_instances_api_endpoint

    # Get Active schedules
    temp_result = requests.get(url,headers={'Authorization': 'Bearer ' + token},verify=customVerify).json()
    if 'error' in temp_result.keys():
        print()
        print("Error: " + temp_result["error"]["message"])
        print()
        print("Need help?")
        print("Check if you are on the correct subscription and tenant")
        print("These commands are available")
        print("  az account show       See your currently logged in environment")
        print("  az logout             Logout of the current environment")
        print()
        print("You can also use the --reauth and --tenant xxxxxx.onmicrosoft.com parameters to force a reauthentication")
        
        exit()
    else:
        if trace:
            print("TRACE: Active Schedules:")
            print(temp_result)

        for value in temp_result["value"]:
                entry={}
                entry["roleDefinitionId"]                 = value["properties"]["roleDefinitionId"]
                entry["scope"]                            = value["properties"]["scope"]
                entry["name"]                             = value["name"]
                entry["principalId"]                      = value["properties"]["principalId"]
                entry["state"]                            = value['properties']['status']

                results.append(entry)


    return results

######################################################
#  Get a list of eligible schedules/roles using Rest API
######################################################
def get_roles_eligible(token=None,scope=None,subscription=None,resourceGroup=None,managementGroup=None):
    results = ([])

    # If Management group or subscription was passed, add it to the scope
    if managementGroup:
        scope = "/providers/Microsoft.Management/managementGroups/" + managementGroup
    
    if subscription:
        scope = "/subscriptions/" + subscription
        if resourceGroup:
            scope+= "/resourceGroups/" + resourceGroup

    # In all cases, add a trailing slash   
    if scope:   
        scope+="/"
    else:
        scope="/"


    # get available roles (includes active)
    get_role_eligibility_api_endpoint = "https://management.azure.com" + \
        scope + \
        "providers/Microsoft.Authorization/roleEligibilityScheduleInstances" + \
        "?$filter=asTarget()&api-version=2020-10-01-preview"

    url =  get_role_eligibility_api_endpoint

    # Get Elibible schedules
    temp_result = requests.get(url,headers={'Authorization': 'Bearer ' + token},verify=customVerify).json()
    if 'error' in temp_result.keys():
        print("Error: " + temp_result["error"]["message"])
        exit()
    else:
        if trace:
            print()
            print("TRACE: Eligible Schedules:")
            print(temp_result)

        for value in temp_result["value"]:
            entry={}
            entry["roleEligibilityScheduleId"]   = value["properties"]["roleEligibilityScheduleId"]
            entry["roleDefinitionId"]            = value["properties"]["roleDefinitionId"] #value["properties"]["roleDefinitionId"].split('/')[-1]
            entry["scope"]                       = value["properties"]["scope"]
            entry["name"]                        = value["name"]
            entry["principalId"]                 = value["properties"]["principalId"]
            entry["state"]                       = value["properties"]["status"]
            results.append(entry)

    
    return results

######################################################
#  print a list of active/eligible roles
######################################################
def list_roles_all(token=None,scope=None,subscription=None,resourceGroup=None,managementGroup=None):
    activeAssignments = get_roles_active(token,scope,subscription,resourceGroup,managementGroup)
    
    col_format="{: <40} {: <40}"
    

    print()
    
    print ("Note: Active roles report may be delayed by up to 5 minutes")
    print(f"{BOLD}")
    print(col_format.format("Active Role","Scope"))
    print(f"{NORMAL}",end="")
    if activeAssignments:
        for entry in activeAssignments:
            print(col_format.format(get_role_display_name(entry["roleDefinitionId"].split("/")[-1]),
                                    entry["scope"] 
                                    ))
    else:
        print("No active roles found")

    eligibleAssignments = get_roles_eligible(token,scope,subscription,resourceGroup,managementGroup)
    print()
    print(f"{BOLD}")
    print(col_format.format("Eligible Role","Scope"))
    print(f"{NORMAL}",end="")
    if eligibleAssignments:
        for entry in eligibleAssignments:
            print(col_format.format(get_role_display_name(entry["roleDefinitionId"].split("/")[-1]),
                                    entry["scope"]
                                    ))
    else:
        print("No eligible roles found")


######################################################
#  Given a roleId return a Role Name
######################################################
def get_role_display_name(roleId=None):
    if roleId:        
        if roleId in roles:
            return roles[roleId]
        else:
            return roleId

######################################################
#  Given a role name, return a role id
######################################################
def get_role_id(role=None):
    if role:        
        # Lets find role id by name
        # if found, return the key
        if role in roles.values():
            for roleId,roleName in roles.items():
                if roleName.lower() == role.lower():                    
                    return roleId
                
        # but if not found, just return the role         
        else:            
            return role


#####################################################
#  Get a list of management groups using Rest API
###################################################### 
def get_management_group_list(token=None):
    results = ([])

    ######  WIP ###### - Not yet implemented

    # Endpoint for role definitions
    get_management_group_api_endpoint = "https://management.azure.com/" + \
        "providers/Microsoft.Management/managementGroups" + \
        "?api-version=2020-05-01"

    url =  get_management_group_api_endpoint

    # Get Role definitions
    temp_result = requests.get(url,headers={'Authorization': 'Bearer ' + token},verify=customVerify).json()
    if 'error' in temp_result.keys():
        print("Error: " + temp_result["error"]["message"])
        exit()
    else:
        for value in temp_result["value"]:
            entry={}
            entry["roleId"]       = value["name"]
            entry["roleName"]     = value['properties']['roleName']
            entry["RoleType"]     = value["properties"]["type"]
            results.append(entry)
    return results

######################################################
#  Get a list of role definitions using Rest API
###################################################### 
def get_role_definition_list(token=None):
    results = ([])

    # Endpoint for role definitions
    get_role_definition_api_endpoint = "https://management.azure.com/" + \
        "/providers/Microsoft.Authorization/roleDefinitions" + \
        "?api-version=2022-04-01"

    url =  get_role_definition_api_endpoint

    # Get Role definitions
    temp_result = requests.get(url,headers={'Authorization': 'Bearer ' + token},verify=customVerify).json()
    if 'error' in temp_result.keys():
        print("Error: " + temp_result["error"]["message"])
        exit()
    else:
        for value in temp_result["value"]:
            entry={}
            entry["roleId"]       = value["name"]
            entry["roleName"]     = value['properties']['roleName']
            entry["RoleType"]     = value["properties"]["type"]
            results.append(entry)
    return results

######################################################
#  Make a dictionary/hash out of the role definitions
######################################################
def create_role_definition_hash(token=None):
    roleDefinitions = get_role_definition_list(token)
    roles = {}
    if roleDefinitions:
        for entry in roleDefinitions:
            roles[entry["roleId"]] = entry["roleName"]
        return roles

def help_for_bad_login():
    print ()
    print ("Need help?")
    print ("  * Check if the AZ CLI is installed using \"az account show\"")
    print ("  * Conditional access policies blocking access?\n     Check if the AzureActiveDirectory service endpoint is enabled on this subnet, this can cause the block")
    print ("  * Try to pre-authenticate with \"az login\"")
    print ("  * Check PROXY, CA and FIREWALL settings")
    print ("        example:")
    print ("          export HTTPS_PROXY=http://1.2.3.4:8888")
    print ("          export REQUESTS_CA_BUNDLE=\"/etc/ssl/certs/ca-certificates.crt\"")

    
    

###########################################################
#
#                        MAIN
#
###########################################################

#########
# statics
#########

# Colors for print
BOLD = '\033[96m'
NORMAL = '\x1b[0m'

# Custom PIM Duration
customPIMDuration="PT8H"

# Custom PIM default justification (can be overriden with --message)
#customPIMJustification="Access to Azure resources"

# custom Verify option for the requests module
customVerify=None

# custom AZ CLI Path
customAzureCLIPath=f"<enter the path here>"

# default path for az cli on linux
AzCliPath="az"

# However, on windows, use the full path
if sys.platform == "win32":
    if (os.path.exists("C:\\Program Files (x86)\\Microsoft SDKs\\Azure\\CLI2\\wbin\\az.cmd")):
        AzCliPath=f"C:\\Program Files (x86)\\Microsoft SDKs\\Azure\\CLI2\\wbin\\az.cmd"
    elif (os.path.exists("C:\\Program Files\\Microsoft SDKs\\Azure\\CLI2\\wbin\\az.cmd")):
        AzCliPath=f"C:\\Program Files\\Microsoft SDKs\\Azure\\CLI2\\wbin\\az.cmd"
    elif (os.path.exists(customAzureCLIPath)):
        AzCliPath=customAzureCLIPath
    else:
        print("Error: Azure CLI not found, update the customAzureCLIPath variable on this script")
        exit()
#####################################
# Command line parameters definition
#####################################

parser = argparse.ArgumentParser(
    description="Work with PIM roles",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=textwrap.dedent('''Examples:
     # List your current active and eligible roles for the current az cli subscription
          python pim_activate.py --list
     
     # List your current active and eligible roles for the specified subscription / resource group
          python pim_activate.py --list --subscription MSDN
          python pim_activate.py --list --subscription MSDN --resource-group MyVmGroup

     # List your current active and eligible roles for the specified scope
          python pim_activate.py --list --scope /subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Compute/virtualMachines/xxxxx                               

     # Activate a role for the current az cli subscription
          python pim_activate.py --role role-name-or-id --message "Justification for the activation"
                           
     # Activate a role for the specified subscription / resource group
          python pim_activate.py --subscription MSDN --role role-name-or-id --message "Justification for the activation"
          python pim_activate.py --subscription MSDN --resource-group MyVmGroup --role role-name-or-id --message "Justification for the activation"
                           
    # Activate a role for the specified scope
        python pim_activate.py --scope /subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Compute/virtualMachines/xxxxx --role role-name-or-id --message "Justification for the activation"

    # Schedule a role activation
          python pim_activate.py --start-time "2023-12-19T15:30:00"    --role role-name-or-id --message "Justification for the activation"''')
           )  

parser.add_argument("-g","--resource-group", metavar="",type=str,default=None,help="The resource group of the VM")
parser.add_argument("-s","--subscription", metavar="", type=str,default=None,help="The subscription id")
parser.add_argument("--management-group", metavar="", type=str,default=None,help="The management group id (only supports the id, not the name)")
parser.add_argument("--scope", metavar="", type=str,default=None,help="The target scope. Use this when the scope is a resource, ex: /subscriptions/xxxxx/resourceGroups/xxxxx/providers/Microsoft.Compute/virtualMachines/xxxxx")
parser.add_argument("--start-time", metavar="", type=str,default=None,help="The start time for the activation in format 2023-12-12T15:50:21 [4digitYear]-[Month]-[DayT24HourFormat]:[Minutes]:[Seconds]")

parser.add_argument("-t","--tenant", metavar="",type=str, default=None, help="The tenant id")
parser.add_argument("-r","--role", metavar="",type=str, default=None, help="The role to activate, valid values are: user,admin,<role name>,<role id>, or a list of comma separated roles")

parser.add_argument("-f ","--reauth", action='store_true',help="Force reauthentication, use it when switching tenants.")
parser.add_argument("-l ","--list", action='store_true',help="List active and eligible roles")
parser.add_argument("-n","--name", metavar="",type=str, default=None, help="The name of the VM")
parser.add_argument("-m","--message", metavar="",type=str, default=None, help="Message/Justification to include on the Activation request")

parser.add_argument("-d ","--debug", action='store_true',help="Enable debug output")
parser.add_argument("--trace", action='store_true',help="Enable trace output")
parser.add_argument("--use-default-login-method", action='store_true',help="Use the default login method")
args = parser.parse_args()

subscription = args.subscription
resourceGroup = args.resource_group
managementGroup = args.management_group
scope = args.scope
tenant = args.tenant
role = args.role
debug = args.debug
reauth = args.reauth
list = args.list
trace = args.trace
message = args.message
startTime = args.start_time
defaultLoginMethod = args.use_default_login_method

################################
# Check for required parameters
################################


if (not list) and ((not role )):
    parser.print_help()
    print()
    print(">>>>>> Error: Missing required parameter, use --role or --list <<<<<<")
    exit(1)

if (not list) and (not message):
    parser.print_help()
    print()
    print(">>>>>> Error: A justification is required, use --message <<<<<<")
    exit(1)

######################################
# Workflow starts here
######################################
print()
print ("===================================")
print ("PIM Activator for Azure Roles v0.4")
print ("===================================")


# Start Login process
loginUser = login(tenant)

# If we logged in...
if loginUser:
    print (f"   Welcome{BOLD}",loginUser,f"{NORMAL}")

  # Check for subscription
    # if (not subscription):

    #     (subscription,subName) = get_current_subscription()
    #     print()
    #     print ("   Using current Azure CLI subscription: ",subName, " (",subscription,")")
    #     if (subName == 'N/A(tenant level account)'):
    #         subscription = None

    # else:
    #     # Set the current subscription if one was passed
    #     set_current_subscription(subscription)

    #     # get the id of the subscription, in case the name was passed.
    #     (subscription,subName) = get_current_subscription()

  # Start Access token acquisition process
    print ("   Requesting access token ...",end="")
    tokenResult = get_access_token()

    token = tokenResult["accessToken"]

    principalId = get_user_object_id(token)
    upn = get_user_upn(token)
        
    
  # Download Role Definitions and get the requested role id
    print("   Downloading list of role definitions...")  
    roles=create_role_definition_hash(token)

  # If the list parameter was passed, show role schedules info then exit
    if list:
        print ("   Getting list of role schedules ...")
        list_roles_all(token,scope,subscription,resourceGroup)
        exit()

    # If the role parameter was specified, calculate needed role id
    if role:
        roleList=re.split('\,',role)
        for role in roleList:
            activateThis = get_role_id(role)

            # Start PIM Process/RoleActivation
            print()
            print (f"   Activating role {BOLD}{get_role_display_name(activateThis)} {NORMAL} (this may take some time) .",end="",flush=True)

            # Get list of eligible assignments
            if debug:
                    print("Getting List of Eligible Roles")
            else:
                print (".",end="",flush=True)

            eligibleAssignments = get_roles_eligible(token,scope,subscription,resourceGroup,managementGroup)
            
            # Find the assignment that can cover the scope
            selectedAssignment  = find_matching_schedule(activateThis,eligibleAssignments)

            # If we found a matching role that covers the scope....
            if selectedAssignment:
                if debug:
                    print("Getting List of Active Roles")
                else:                
                    print (".",end="",flush=True)
                if not startTime:       
                    # Check if the role is already active
                    # But only if we are not scheduling the activation
                    activeAssignments = get_roles_active(token,scope,subscription,resourceGroup,managementGroup)
                    roleAlreadyActive = is_role_already_active(selectedAssignment,activeAssignments)
                else:
                    roleAlreadyActive = False
                if (not roleAlreadyActive):
                    if debug:
                        print("Activating eligible role")
                    else:
                        print (".")
                    
                    activate_eligible_assignment(token=token,
                            eligibleAssignment=selectedAssignment,
                            principalId=principalId,
                            justification=message
                            )
                    
                else:
                    print()
                    print ("   Already Active!")
            # if we did not find a matching role that covers the scope        
            else:
                print()
                print ("   ERROR: No eligible assignment found, use --list to see a list of available roles")
        exit()


  # If we got here it's because then we are done




else:
    print ("Aborting due to login error")
    help_for_bad_login()




