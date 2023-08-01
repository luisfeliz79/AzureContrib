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

# Python module install instructions
#     python -m pip install requests uuid datetime argparse

# For updates, visit
# https://github.com/luisfeliz79/AzureContrib/tree/dev/az-ssh-and-pim


######################################################
#  Given an access token, return the user's object id
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
        return decodedAccessToken['unique_name']

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
        print("Error getting access token")
        exit()

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
        print("Error setting subscription")
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
#  Wrapper function for az ssh vm
######################################################
def connect_via_aadssh(vmName=None,resourceGroupName=None,port=None,ip=None):

    print("")

    if ip: 
        cmd=([AzCliPath,'ssh','vm','--ip',ip])
    elif(is_String_An_IP(vmName)):
        cmd=([AzCliPath,'ssh','vm','--ip',vmName])
    elif resourceGroupName and vmName and (not is_String_An_IP(vmName)):
        cmd=([AzCliPath,'ssh','vm','--resource-group',resourceGroupName,"--name",vmName])
    else:
        print("Error: Invalid parameters")
        exit()
    if cmd:
        if port:
            cmd.append('--port')
            cmd.append(port)

        if debug:
            print("DEBUG: About to run: ",cmd)

        print()
        print (' '.join(cmd))
        print()    
        subprocess.call(cmd, shell=False)

######################################################
#  login function which checks if user is already logged in
######################################################
def login(tenant=None):

    if reauth:
        # If reauth as specified, then request login
        logout()
        userName = login_with_device_code(tenant)
        return userName

    cmd=([AzCliPath,'account','show'])

    if debug:
        print("DEBUG: About to run: ",cmd)

    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,shell=False)
    
    output = p.stdout.decode()
    err = p.stderr.decode()


    if err:
        # If we got an error, assume we need to login
        userName = login_with_device_code(tenant)
        return userName

    if output:
        # If we got output, assume we are already logged in
        loginResult = json.loads(output)
        return loginResult['user']['name']

######################################################
#  Login using Azure AD Device Code authentication
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
        #print(output.decode())
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

        # Create the payload
        dt = datetime.utcnow()
        payload={}
        payload["properties"] = {}
        payload["properties"]["principalId"] = principalId
        payload["properties"]["roleDefinitionId"] = eligibleAssignment["roleDefinitionId"]
        payload["properties"]["linkedRoleEligibilityScheduleId"] = eligibleAssignment["roleEligibilityScheduleId"]
        payload["properties"]["requestType"] = "SelfActivate"
        payload["properties"]["justification"] = justification
        payload["properties"]["scheduleInfo"] = {}
        payload["properties"]["scheduleInfo"]["startDateTime"] = dt.strftime("%Y-%m-%dT%H:%M:%S.%fZ") #"2023-07-04T21:31:27.91Z"
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
def get_roles_active(token=None):
    results = ([])

    scope = "subscriptions/" + subscription + "/resourceGroups/" + resourceGroup

    # get currently active roles
    active_elegibility_schedule_instances_api_endpoint = "https://management.azure.com/" + \
        scope + \
        "/providers/Microsoft.Authorization/roleAssignmentSchedules" + \
        "?$filter=asTarget()&api-version=2020-10-01-preview"
    
    url = active_elegibility_schedule_instances_api_endpoint

    # Get Active schedules
    temp_result = requests.get(url,headers={'Authorization': 'Bearer ' + token},verify=customVerify).json()
    if 'error' in temp_result.keys():
        print("Error1: " + temp_result["error"]["message"])
        print()
        print("Need help?")
        print("Check if you are on the correct environment/tenant")
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
def get_roles_eligible(token=None):
    results = ([])

    scope = "subscriptions/" + subscription + "/resourceGroups/" + resourceGroup

    # get available roles (includes active)
    get_role_eligibility_api_endpoint = "https://management.azure.com/" + \
        scope + \
        "/providers/Microsoft.Authorization/roleEligibilityScheduleInstances" + \
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
def list_roles_all(token=None):
    activeAssignments = get_roles_active(token)
    
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

    eligibleAssignments = get_roles_eligible(token)
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

######################################################
#  Used to determine if a string is an IP address
######################################################
def is_String_An_IP(string=None):

    if string:
        # Check if string is an IPV4 address
        if re.match('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', string) != None:
            return True
        # Check if string is an IPV6 address
        if re.match('([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}', string) != None:
            return True
    #other wise, just return false
    return False

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
customPIMDuration="PT1H"

# Custom PIM default justification (can be overriden with --message)
customPIMJustification="Shell access to virtual machine"

# custom Verify option for the requests module
customVerify=None

# default path for az cli on linux
AzCliPath="az"

# However, on windows, use the full path
if sys.platform == "win32":
    AzCliPath=f"C:\\Program Files (x86)\\Microsoft SDKs\\Azure\\CLI2\\wbin\\az.cmd"

#####################################
# Command line parameters definition
#####################################

parser = argparse.ArgumentParser(
    description="Activate a PIM role and login to a VM",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=textwrap.dedent('''Examples:
     # Connect with Subscription, Resource Group and VM Name
          python pimssh.py --resource-group MyVmGroup --subscription MSDN --name myazurevm

     # Connect with Subscription, Resource Group and IP address
          python pimssh.py --resource-group MyVmGroup --subscription MSDN --name 10.20.30.40
          python pimssh.py --resource-group MyVmGroup --subscription MSDN --ip 10.20.30.40
                           
     # Login with administrative rights (default is user rights)
          python pimssh.py --resource-group MyVmGroup --subscription MSDN --ip 10.20.30.40 --role admin
 
     # Use a custom port other than 22
          python pimssh.py --resource-group MyVmGroup --subscription MSDN --ip 10.20.30.40 --port 2222
                                                      
     # Including a tenant name (Use for Cross Tenant Scenarios)
          python pimssh.py --resource-group MyVmGroup --subscription \"fb87000d-0000-0000-0000-7e100000005\" --name myazurevm --tenant demo.onmicrosoft.com''')
           )  

parser.add_argument("-g","--resource-group", metavar="",type=str,default=None,help="The resource group of the VM")
parser.add_argument("-s","--subscription", metavar="", type=str,default=None,help="The subscription id")
parser.add_argument("-t","--tenant", metavar="",type=str, default=None, help="The tenant id")
parser.add_argument("-r","--role", metavar="",type=str, default=None, help="The role to activate, use admin or specify a role id")
parser.add_argument("-p","--port", metavar="",type=str, default=None, help="The port to use for SSH. Default is 22")
parser.add_argument("-f ","--reauth", action='store_true',help="Force reauthentication, use it when switching tenants.")
parser.add_argument("-l ","--list", action='store_true',help="List active and eligible roles")
parser.add_argument("-n","--name", metavar="",type=str, default=None, help="The name of the VM")
parser.add_argument("-m","--message", metavar="",type=str, default=None, help="Message/Justification to include on the Activation request")
parser.add_argument("--ip", metavar="",type=str, default=None, help="Connect using IP address instead, --name ip-address also works")
parser.add_argument("-d ","--debug", action='store_true',help="Enable debug output")
parser.add_argument("--trace", action='store_true',help="Enable trace output")

args = parser.parse_args()

subscription = args.subscription
resourceGroup = args.resource_group
tenant = args.tenant
role = args.role
debug = args.debug
reauth = args.reauth
virtualMachine = args.name
list = args.list
ip = args.ip
port = args.port
trace = args.trace
message = args.message

################################
# Check for required parameters
################################

if ((not resourceGroup) or ((not virtualMachine ) and (not ip))) and (not list):
    parser.print_help()
    exit(1)


######################################
# Workflow starts here
######################################
print()
print ("===================================")
print ("PIM + AAD SSH v1.0.1")
print ("===================================")

# Start Login process
loginUser = login(tenant)

# If we logged in...
if loginUser:
    print (f"   Welcome{BOLD}",loginUser,f"{NORMAL}")

  # Check for subscription
    if (not subscription):
        print ("Please specify a subscription using --subscription")
        exit()

    else:
        # Set the current subscription if one was passed
        set_current_subscription(subscription)

        # get the id of the subscription, in case the name was passed.
        (subscription,subName) = get_current_subscription()

  # Start Access token acquisition process
    print ("   Requesting access token ...",end="")
    tokenResult = get_access_token()

    token = tokenResult["accessToken"]

    principalId = get_user_object_id(token)
    upn = get_user_upn(token)
    
  # Download Role Definitions and get the requested role id
    print("   Downloading list of role definitions...")  
    roles=create_role_definition_hash(token)
    roleAdminLogin=get_role_id("Virtual Machine Administrator Login")
    roleUserLogin=get_role_id("Virtual Machine User Login")

    # If the role parameter was specified, calculate needed role id
    if role:
        if role.lower() == "admin":
            activateThis = roleAdminLogin
        elif role.lower() == "user":
            activateThis = roleUserLogin
        else:
            # If role is not admin or user, then assume another specific role was specified
            activateThis = get_role_id(role)
    # If the role parameter was not specified, then use the default
    else:
        # Default is user role
        activateThis = roleUserLogin

  # If the list parameter was passed, show role schedules info then exit
    if list:
        print ("   Getting list of role schedules ...")
        list_roles_all(token)
        exit()

  # Start PIM Process/RoleActivation
    print (f"   Activating role {BOLD}{get_role_display_name(activateThis)} {NORMAL} (this may take some time) .",end="",flush=True)

    # Get list of eligible assignments
    print (".",end="",flush=True)
    eligibleAssignments = get_roles_eligible(token)

    # Find the assignment that can cover the scope
    selectedAssignment  = find_matching_schedule(activateThis,eligibleAssignments)

    # If we found a matching role that covers the scope....
    if selectedAssignment:
        # Then check existing active assignments in case it is already active
        print (".",end="",flush=True)
        activeAssignments = get_roles_active(token)
        
        # Check if the role is already active
        roleAlreadyActive = is_role_already_active(selectedAssignment,activeAssignments)
        
        if (not roleAlreadyActive):
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


  # If we got here it's because the role was active or has been activated
  # Let's connect to the VM using az ssh vm
    print ("   Connecting to VM ...")
    
    connect_via_aadssh(vmName=virtualMachine,
                       resourceGroupName=resourceGroup,                       
                       port=port,
                       ip=ip
                       )


else:
    print ("Aborting due to login error")
    help_for_bad_login()




