
# Based on https://learn.microsoft.com/en-us/azure/azure-monitor/app/opencensus-python

#python3.9 -m venv pythontest
#pythontest\Scripts\activate
#python3.9 -m pip install opencensus-ext-azure
#export APPLICATIONINSIGHTS_CONNECTION_STRING=''

import logging

from opencensus.ext.azure.log_exporter import AzureLogHandler

logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler())

def main():

    print ("Python Logging to Azure Insights test - start")
    
    properties = {'custom_dimensions': {'key_1': 'value_1', 'key_2': 'value_2'}}

    """Generate random log data."""
    for num in range(5):
        logger.warning(f"Python Log Entry - {num}",extra=properties)

    print ("Python Logging to Azure Insights test - end")
if __name__ == "__main__":
    main()

