# Sample scripts to send log data to Azure Monitor

## Content
- [(Option 1) Sending directly to a Log Analytics Workspace](#option-1-sending-directly-to-a-log-analytics-workspace)

- [(Option 2) Sending via Application Insights](#option-2-sending-via-application-insights)

- [Sample Scenarios](#sample-scenarios)




## (Option 1) Sending directly to a Log Analytics Workspace
### Benefits
- You can send data directly to a Log Analytics Workspace Custom Table.  The script allows you to read a file and either send it all as one Log entry or break it up based on line breaks.

- Data Collection Endpoints allow for private networking using Azure Monitor Private Link Service.

- Data Collection Rules allow for very specific attributes in the table and also transformations.

- Integration with Azure AD Authentication and Authorization.

### Pre-requisites
- A Log Analytics Workspace
- A Custom Table in the Log Analytics Workspace
- A Data Collection Endpoint
- A Data Collection Rule 
- An Azure AD Application with a client secret
- Python modules azure-monitor-ingestion and azure-identity

Note:
This uses the Logs ingestion API
Based on the sample code in this document
https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-code?tabs=python

### Steps

1. Follow [instructions here](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-code?tabs=python) to a create the required resources

2. Download required Python modules
```bash
    python -m pip install azure-monitor-ingestion
    python -m pip install azure-identity
```
3. Configure environment variables
```bash
    export AZURE_TENANT_ID="xxxxx-azure-ad-tenant-id-xxxxx"
    export AZURE_CLIENT_ID="xxxxx-service principal client id or app id-xxxxx"
    export AZURE_CLIENT_SECRET="xxxxx-service principal secret-xxxxx"
```
4. Run the scripts [found here](./python-direct-to-law/)

```bash

    # To send a message from command line
    python send_to_law.py "This is my message"

    # To send the contents of a file and split it by line break

    python send_to_law_from_file.py /path/to/logfile.log

    # To send the contents of a file and treat it a single message

    python send_to_law_from_file.py /path/to/logfile.log -single

```


## (Option 2) Sending via Application Insights

### Benefits
- Application Insights is a performance monitoring toolkit that uses Log Analytics Workspaces as backend storage.

- Simplifies collecting log data from applications by using open source libraries for Python, and using traditional logging methods.

### Pre-requisites
- A Log Analytics Workspace
- An Application Insights resource
- Python module install opencensus-ext-azure

### Steps
- Follow the [instructions here](https://learn.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource) to create an Application Insights resource

2. Download required Python modules
```bash
    python -m pip install opencensus-ext-azure
```

3. Configure environment variables
```bash
    export APPLICATIONINSIGHTS_CONNECTION_STRING='your-app-insights-connection-string'
```
4. Run the scripts [found here](./python-using-app-insights/)
```bash

    # To send a message from command line
    python send_to_ai.py "This is my message"

    # To send the contents of a file and split it by line break    
    python send_to_ai_from_file.py /path/to/logfile.log

```

# Sample Scenarios

# Sending all console output to Log Analytics workspace

```bash
    
    # use the script command to capture all console logging
    script mylog.txt

    ...
    ... your commands here
    ...

    # use exit when done
    exit

    # optionally clean up typescript formatting from the resulting file
    sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" mylog.txt | tr -dc '[[:print:]]\n' > mylog_clean.txt

    # Send it all to Log analytics
    python send_to_law_from_file.py mylog_clean.txt

```
