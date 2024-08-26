# Log data analysis with Kusto Query Language (KQL) in Azure Monitor
# Quick start guide

### Introduction
Azure Monitor stores data in Log Analytics workspaces, which support the Kusto query language (KQL) for data analysis. The queries can also be used for creating dashboards using Azure Workbooks and triggering alerts using Azure Monitor alerts.  The full KQL reference guide is located here: [Kusto Query Language (KQL) reference](https://learn.microsoft.com/en-us/kusto/query/syntax-conventions?view=azure-data-explorer&preserve-view=true)

To access the KQL query editor, open the Azure portal and navigate to the Log Analytics workspace. Click on the Logs menu item to open the query editor.

### Querying tables
Logs are stored in tables, which can be queried by using the table name followed by the query. For example, for the Azure Storage Blob service logs, the table name is `StorageBlobLogs`.  To query  records in the table as per the selected time period, use the following query:

```kql
StorageBlobLogs
```

### Selecting specific columns
By default, all columns are returned in the query results.  To only display specific colums, use the `project` operator followed by the column names. For example, to only show the Time, Blob Name, and operations name and status:

```kql
StorageBlobLogs
| project TimeGenerated, OperationName, StatusCode, ObjectKey
```

### Filtering data
To filter data, use the `where` operator followed by the filter condition. For example, to only show the records where the OperationName is PutBlob:

```kql
StorageBlobLogs
| where OperationName == "PutBlob"
| project TimeGenerated, OperationName, StatusCode, ObjectKey
```

### Creating your own columns
Sometimes, it is helpful to create your own column for further analysis or refinement of the query. The `extend` keyword is used for this and has a general syntax of `extend <columnname> = <expression>`  

In the case below, we want to extract the container name from the ObjectKey (this is the pathname of the Blob).  Notice that we also added the new column name to the project statement

```kql
StorageBlobLogs
| where OperationName == "PutBlob"
| extend ContainerName = split(ObjectKey, "/")[2]
| project TimeGenerated, OperationName, StatusCode, ContainerName,ObjectKey
```

### Summarizing data
To summarize data, use the `summarize` operator followed by the aggregation function and the column name. For example, to count the number of records for each ContainerName:

```kql
// Count the number of records for each ContainerName
// Notice that we wrapped ContainerName with to string to normalize the values in the column to a string type. This is required by the summarize function.

StorageBlobLogs
| where OperationName == "PutBlob"
| extend ContainerName = split(ObjectKey, "/")[2]
| summarize count() by tostring(ContainerName)
```