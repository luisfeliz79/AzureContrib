import subprocess
import sys
import textwrap
import requests
import jwt
import json
import uuid
from datetime import datetime
import argparse
import re

# Python module install instructions
#     python -m pip install requests jwt uuid datetime argparse PyJWT

# Fix for PyJWT module issues
#     python -m pip uninstall jwt==1.0.0
#     python -m pip uninstall PyJWT
#     python -m pip install PyJWT


######################################################
#  Given an access token, return the user's object id
######################################################
def get_user_object_id(token=None):
    if token:
        alg=jwt.get_unverified_header(token)['alg']
        decodedAccessToken = jwt.decode(token, algorithms=[alg], options={"verify_signature": False})  
        return decodedAccessToken['oid']

######################################################
#  Given an access token, return the User Principal Name
######################################################
def get_user_upn(token=None):
    if token:
        alg=jwt.get_unverified_header(token)['alg']
        decodedAccessToken = jwt.decode(token, algorithms=[alg], options={"verify_signature": False})  
        return decodedAccessToken['unique_name']
    
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
        print(" successful")
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

    if ip or (is_String_An_IP(vmName)):
        cmd=([AzCliPath,'ssh','vm','--ip',vmName])

    if resourceGroupName and vmName and (not is_String_An_IP(vmName)):
        cmd=([AzCliPath,'ssh','vm','--resource-group',resourceGroupName,"--name",vmName])

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
def is_role_already_active(roleId=None,scheduleList=None,resourceGroupName=None,subscriptionId=None):
    if scheduleList:
        if roleId:
            for item in scheduleList:
                roleDefinitionId = item["roleDefinitionId"].split('/')[-1]
                if subscriptionId:
                        scope="/subscriptions/"+subscriptionId
                        if resourceGroupName:
                            scope+="/resourceGroups/"+resourceGroupName
                if debug:
                  print ("    rdid:",roleDefinitionId,"\n","   roleid:",roleId,"\n","   itemscope:",item["scope"].lower(),"\n","   scope:",scope.lower())       
                if (roleDefinitionId == roleId) and \
                    ((item["scope"].lower().find(scope.lower())) or \
                     (item["scope"].lower() == scope.lower())):
                    return True
    
    # if we made it here, return False
    return False
           
######################################################
#  Activate a role assignment schedule using Rest API
######################################################                
def activate_eligible_assignment(token=None,
                                 eligibleAssignment=None
                                 ):
    # Check for the token
    if not token:
        print("No access token provided")
        return None
    
  
    if eligibleAssignment:

        # API Base Url
        activate_schedule_api_endpoint = "https://management.azure.com"

        # create a random guid name
        uuid_str = str(uuid.uuid4())
        
        # Add the scope
        activate_schedule_api_endpoint += eligibleAssignment["scope"]

        # Complete the rest of the url
        activate_schedule_api_endpoint += "/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/"+ uuid_str +"?$filter=asTarget()&api-version=2020-10-01-preview"

        # Create the payload
        dt = datetime.utcnow()
        payload={}
        payload["properties"] = {}
        payload["properties"]["principalId"] = eligibleAssignment["principalId"]
        payload["properties"]["roleDefinitionId"] = eligibleAssignment["roleDefinitionId"]
        payload["properties"]["requestType"] = "SelfActivate"
        payload["properties"]["justification"] = "This is a test"
        payload["properties"]["scheduleInfo"] = {}
        payload["properties"]["scheduleInfo"]["startDateTime"] = dt.strftime("%Y-%m-%dT%H:%M:%S.%fZ") #"2023-07-04T21:31:27.91Z"
        payload["properties"]["scheduleInfo"]["expiration"] = {}
        payload["properties"]["scheduleInfo"]["expiration"]["type"] = "AfterDuration"
        payload["properties"]["scheduleInfo"]["expiration"]["endDateTime"] = None
        payload["properties"]["scheduleInfo"]["expiration"]["duration"] = customPIMDuration
        
        if debug:
            print("DEBUG: Url: " + activate_schedule_api_endpoint)
            print("DEBUG: Payload: ")
            print(payload)
        
        result = requests.put(activate_schedule_api_endpoint,
                     json = payload,
                     headers={'Authorization': 'Bearer ' + token}
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
    else:
        print("No eligible assignment provided")
        return None

######################################################
#  Get a list of active schedules/roles using Rest API
###################################################### 
def get_active_user_roles_at_scope(token=None,subscriptionId=None,resourceGroupName=None):
    results = ([])

    if subscriptionId:
        scope = "providers/Microsoft.Subscription/subscriptions/" + subscriptionId
    if resourceGroupName:
        scope += "/resourceGroups/" + resourceGroupName 

    url_dict = {}

    # get currently active roles
    active_elegibility_schedule_instances_api_endpoint = "https://management.azure.com/" + \
        scope + \
        "/providers/Microsoft.Authorization/roleAssignmentSchedules" + \
        "?$filter=asTarget()&api-version=2020-10-01-preview"
    
    url = active_elegibility_schedule_instances_api_endpoint

    # Get Active schedules
    temp_result = requests.get(url,headers={'Authorization': 'Bearer ' + token}).json()
    if 'error' in temp_result.keys():
        print("Error: " + temp_result["error"]["message"])
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
        if debug:
            print("DEBUG: Active Schedules:")
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
def get_user_roles_at_scope(token=None,subscriptionId=None,resourceGroupName=None):
    results = ([])

    if subscriptionId:
        scope = "providers/Microsoft.Subscription/subscriptions/" + subscriptionId
    if resourceGroupName:
        scope += "/resourceGroups/" + resourceGroupName 

    url_dict = {}

    # get available roles (includes active)
    get_role_eligibility_api_endpoint = "https://management.azure.com/" + \
        scope + \
        "/providers/Microsoft.Authorization/roleEligibilityScheduleInstances" + \
        "?$filter=asTarget()&api-version=2020-10-01-preview"

    url =  get_role_eligibility_api_endpoint

    # Get Elibible schedules
    temp_result = requests.get(url,headers={'Authorization': 'Bearer ' + token}).json()
    if 'error' in temp_result.keys():
        print("Error: " + temp_result["error"]["message"])
        exit()
    else:
        if debug:
            print()
            print("DEBUG: Eligible Schedules:")
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
def list_roles_at_scope(token=None,subscriptionId=None,resourceGroupName=None):
    activeAssignments = get_active_user_roles_at_scope(token,subscriptionId=subscription,resourceGroupName=resourceGroup)
    col_format="{: <40} {: <40}"
    col2_format="{: <40} {: <20} {: <20}"

    print()
    
    print ("Note: Active roles report may be delayed by up to 5 minutes")
    print()
    print(col_format.format("Active Role","Scope"))
    if activeAssignments:
        for entry in activeAssignments:
            print(col_format.format(get_role_display_name(entry["roleDefinitionId"].split("/")[-1]),
                                    entry["scope"] 
                                    ))
    else:
        print("No active roles found")

    eligibleAssignments = get_user_roles_at_scope(token, subscription,resourceGroup)
    print()
    
    print(col_format.format("Eligible Role","Scope"))
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
    temp_result = requests.get(url,headers={'Authorization': 'Bearer ' + token}).json()
    if 'error' in temp_result.keys():
        print("Error: " + temp_result["error"]["message"])
        exit()
    else:
        if debug:
            print()
            print("DEBUG: Role definitions payload:")
            print(temp_result)

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
    print ("  Check if the AZ CLI is installed using \"az account show\"")
    print ("  Conditional access policies blocking access?\n     Check if the AzureActiveDirectory service endpoint is enabled on this subnet, this can cause the block")
    print ("  Try to pre-authenticate with \"az login\"")

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
                           
     # Including a tenant name (Great for B2B Scenarios)
          python pimssh.py --resource-group MyVmGroup --subscription \"fb87000d-0000-0000-0000-7e100000005\" --name myazurevm --tenant demo.onmicrosoft.com''')
           )  

parser.add_argument("-g","--resource-group", metavar="",type=str,default=None,help="The resource group of the VM")
parser.add_argument("-s","--subscription", metavar="", type=str,default=None,help="The subscription id")
parser.add_argument("-t","--tenant", metavar="",type=str, default=None, help="The tenant id")
parser.add_argument("-r","--role", metavar="",type=str, default=None, help="The role to activate, use admin or specify a role id")
parser.add_argument("-p","--port", metavar="",type=str, default=None, help="The port to use for SSH. Default is 22")
parser.add_argument("-d ","--debug", action='store_true',help="Enable debug output")
parser.add_argument("-f ","--reauth", action='store_true',help="Force reauthentication, use it when switching tenants.")
parser.add_argument("-l ","--list", action='store_true',help="List active and eligible roles")
parser.add_argument("-n","--name", metavar="",type=str, default=None, help="The name of the VM")
parser.add_argument("--ip", metavar="",type=str, default=None, help="Connect using IP address instead, --name ip-address also works")

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

################################
# Check for required parameters
################################
if (not resourceGroup) or ((not virtualMachine ) and (not ip)):
    parser.print_help()
    exit(1)


######################################
# Workflow starts here
######################################
print()
print ("===================================")
print ("PIM + AAD SSH v1.0")
print ("===================================")

# Start Login process
loginUser = login(tenant)

# If we logged in...
if loginUser:
    print (f"   Welcome{BOLD}",loginUser,f"{NORMAL}")

  # Configure the AZ CLI current subscription
    if subscription:
        # Set the current subscription if one was passed
        set_current_subscription(subscription)

        # get the id of the subscription, in case the name was passed.
        (subscription,subName) = get_current_subscription()
    else:
        # otherwise, get the current one
        (subscription,subName) = get_current_subscription()

    print (f"   Using subscription {BOLD}{subName} ({subscription}){NORMAL}")


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
        list_roles_at_scope(token,subscriptionId=subscription,resourceGroupName=resourceGroup)
        exit()

  # Start PIM Process/RoleActivation
    print (f"   Activating role {BOLD}{get_role_display_name(activateThis)} ...{NORMAL} (this may take some time)")

    # First check if the Assignment is already active
    activeAssignments = get_active_user_roles_at_scope(token,subscriptionId=subscription,resourceGroupName=resourceGroup)
    if activeAssignments:
        roleAlreadyActive = is_role_already_active(activateThis,activeAssignments,subscriptionId=subscription,resourceGroupName=resourceGroup)
    else:
        roleAlreadyActive = False

    # However, if it is not active, then check if it is eligible, and activate it
    if (not roleAlreadyActive):
        eligibleAssignments = get_user_roles_at_scope(token, subscription,resourceGroup)

        selectedAssignment  = find_matching_schedule(activateThis,eligibleAssignments)

        # If we found a matching role that covers the scope....
        if selectedAssignment:
            activate_eligible_assignment(token=token,
                                eligibleAssignment=selectedAssignment,
                                )
        else:
            print()
            print ("ERROR: No eligible assignment found, use --list to see a list of available roles")
            exit()
    else:
        print ("   Already Active!")

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




