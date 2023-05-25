
# Based on https://learn.microsoft.com/en-us/azure/azure-monitor/app/opencensus-python
 
# python -m venv pythontest
# pythontest\Scripts\activate
# python -m pip install opencensus-ext-azure
# export APPLICATIONINSIGHTS_CONNECTION_STRING='your-app-insights-connection-string'
 
import logging
import sys
 
from opencensus.ext.azure.log_exporter import AzureLogHandler
 
logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler())

ApplicationName  = "ConsoleLog"

#Check if a message was passed
if len(sys.argv) < 2:
    print("No message passed")
    sys.exit()

message = sys.argv[1]

    
# Optionally specify some additional properties for the log record
properties = {'custom_dimensions': {'ApplicationName': 'ConsoleLog'}}

# Log the data to Application Insights
message = message.strip()
logger.warning(message,extra=properties)

print ("Sent!")
