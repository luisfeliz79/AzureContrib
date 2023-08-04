# App Insights with Tags demo


## Description

- This sample showcases auto-instrumentation and tagging features of App Insights for Java. It uses the Application Insights Java agent, which automatically ingests data from popular libraries, see [here for more info](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-overview)
- The demoapp runs emulates a data process and includes attribute "jobName" for each run.   After serveral runs, you can examine metrics and traces at the job level using the included workbook.


- Take a look at the [App Insights configuration](./applicationinsights.json)
  - The inheritedAttributes configuration directive should include a list of attributes you want to include on ingested telemetry. These need to match what has been defined as tags in the code.
        This is related to [this feature](https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-standalone-config#inherited-attribute-preview)

- Application Insights will automaticall ingest:
    - Logback traces
    - Open Telemetry Libraries instrumentation
    - Micrometer instrumentation using the globalRegistry
    - And much more -> [More info](https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-standalone-config)

- The tag data can be used with KQL Queries and Workbooks/Dashboard visualizations.

![](./workbook/workbook-sample.png)


## Running the demo app

### Pre-reqs
- Create an App Insights (workspace based)
- A Service principal with a Secret credential
- Create an Azure Storage Account with Hierarchical namespace
- Give the service principal "Storage Blob Data Contributor" RBAC permssision to the storage account
- Visual Studio code


    
    
### Required variables
```powershell
    # PowerShell
    $ENV:AZURE_TENANT_ID = "xxx"
    $ENV:AZURE_CLIENT_ID = "xxx"
    $ENV:AZURE_CLIENT_SECRET = "xxx"
    $ENV:STORAGE_ACCOUNT_NAME = "<storage-account-name>"  
    $ENV:APPLICATIONINSIGHTS_CONNECTION_STRING = "<app-insights-conn-string>"

    # Bash
    export AZURE_TENANT_ID="xxx"
    export AZURE_CLIENT_ID="xxx"
    export AZURE_CLIENT_SECRET="xxx"
    export STORAGE_ACCOUNT_NAME="<storage-account-name>"  
    export APPLICATIONINSIGHTS_CONNECTION_STRING="<app-insights-conn-string>"
```
### Optional variables
```bash
# You can use an environment variable to define the Application Insights configuration instead of a file
# Example:
export APPLICATIONINSIGHTS_CONFIGURATION_CONTENT=$(
cat <<'END_DATA'
{
  "role": {
    "name": "TaggingDemoClient"
  },
  "preview": {
    "captureControllerSpans": false,
    "inheritedAttributes": [
      {
        "key": "jobName",
        "type": "string"
      }

    ]
  },
  "sampling": {
    "percentage": 100
  },
  "instrumentation": {
    "logging": {
      "level": "INFO"
    },
    "micrometer": {
      "enabled": true
    }
  },
  "heartbeat": {
    "intervalSeconds": 60
  },
  "selfDiagnostics": {
    "destination": "file",
    "level": "DEBUG",
    "file": {
      "path": "applicationinsights.log",
      "maxSizeMb": 5,
      "maxHistory": 1
    }
  },
  "jmxMetrics":[]
}
END_DATA
)
```

### Run the sample using Docker
```bash
sudo docker run  -e "AZURE_TENANT_ID=$AZURE_TENANT_ID" -e "AZURE_CLIENT_ID=$AZURE_CLIENT_ID" -e "AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET" -e "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPLICATIONINSIGHTS_CONNECTION_STRING" -e "STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME" luisfeliz79/appinsightsdemo
```

### Run the sample directly
```bash    
cd appinsights-and-tagging-demo/demoapp
mvn clean 
mvn package    

java -javaagent:../applicationinsights-agent-3.4.12.jar -jar ./target/demoapp-1.0.jar
```


## Installing the included Workbook

- In the Azure Portal, use the top search bar to search for "Workbooks"
- Click Create Workbook
- Click New
- Click on the Advanced Editor Icon </>
- Copy and paste the contents of [workbook.json](./workbook/workbook.json)
- Click Apply
- Click Save

