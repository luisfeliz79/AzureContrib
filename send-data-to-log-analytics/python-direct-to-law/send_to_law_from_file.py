
# Based on
# https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-code?tabs=python

# Pre-requisites
    # python -m venv pythonlaw
    # pythonlaw\Scripts\activate
    # python -m pip install azure-monitor-ingestion
    # python -m pip install azure-identity

############################################################
########## Make sure these environment variables are set
############################################################

# export AZURE_TENANT_ID="xxxxx-azure-ad-tenant-id-xxxxx"
# export AZURE_CLIENT_ID="xxxxx-service principal client id or app id-xxxxx"
# export AZURE_CLIENT_SECRET="xxxxx-service principal secret-xxxxx"
# This Service principal should role "Monitoring Metrics Publisher" on the DCR

# Import required modules
import os
import sys
import datetime
from azure.identity import DefaultAzureCredential
from azure.monitor.ingestion import LogsIngestionClient
from azure.core.exceptions import HttpResponseError


# information needed to send data to the DCR endpoint
dce_endpoint     = "https://xxxxx.ingest.monitor.azure.com" # ingestion endpoint of the Data Collection Endpoint object
dcr_immutableid  = "dcr-a9ac25c7569047c495ea1153402b5bac"   # immutableId property of the Data Collection Rule
stream_name      = "Custom-ConsoleLog_CL"                   # name of the stream in the DCR that represents the destination table
ApplicationName  = "ConsoleLog"                             # Your choice. The name of your app

#Check if a filename was passed
if len(sys.argv) < 2:
   print("No file specified")
   sys.exit()

#Check if readmode was passed
if (len(sys.argv) == 3):
    if (sys.argv[2] == "-single"):
        mode = "single"        
    else:
        mode = "splitByLine"
else:
    mode = "splitByLine"

# Open and read the file
try:
    fileName = sys.argv[1]
    fileObject = open(fileName, "r")

    if mode == "single":    
        message=fileObject.read()
        print(f"Log file will be treated as a single message")

    if mode == "splitByLine":
        messages=fileObject.readlines()
        print(f"Log file will be split by line")
    
    fileObject.close()
except:
    print("Error opening file")
    sys.exit()


# Define authentication for the Log Ingestion API
credential = DefaultAzureCredential()

# Create the client
client = LogsIngestionClient(endpoint=dce_endpoint, credential=credential, logging_enable=True)

body = []
currentTime = str(datetime.datetime.now(datetime.timezone.utc))

# Create the payload for a single message
if mode == "single":    
    body.append ({
            "TimeGenerated": currentTime,
            "RawData": message.strip(),
            "Application": ApplicationName
            })
    

# Create the payload for a multiple messages
if mode == "splitByLine":
    for message in messages:
        
        message = message.strip()
        # Create the payload
        body.append ({
                "TimeGenerated": currentTime,
                "RawData": message,
                "Application": ApplicationName
                })
        

# Send the payload
try:
    client.upload(rule_id=dcr_immutableid, stream_name=stream_name, logs=body)
except HttpResponseError as e:
    print(f"Upload failed: {e}")
    sys.exit()

print(f"Sent!")