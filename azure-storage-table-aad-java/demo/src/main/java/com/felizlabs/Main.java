package com.felizlabs;

import java.util.HashMap;
import java.util.Map;

// Include the following imports to use table APIs
import com.azure.data.tables.TableClient;
import com.azure.data.tables.TableServiceClient;
import com.azure.data.tables.TableServiceClientBuilder;
import com.azure.data.tables.models.TableEntity;
import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.DefaultAzureCredentialBuilder;

public class Main {

    
    public static void main(String[] args) {
        
        // Get the storage account name from the environment variable
        String storageAccountName="";
        
        try {
              storageAccountName = System.getenv("STORAGE_ACCOUNT_NAME");
              if (storageAccountName == null) {
                    throw new NullPointerException();
              }          
        } catch (NullPointerException badEnv) {
              System.out.println("STORAGE_ACCOUNT_NAME environment variable not set");
              System.exit(1);
        }

        // Set the storage table endpoint
        final String endPoint = String.format("%s%s%s","https://",storageAccountName,".table.core.windows.net");

        // Create a DefaultAzureCredential instance
        // https://learn.microsoft.com/en-us/java/api/com.azure.identity.defaultazurecredential?view=azure-java-stable
        // This method will try different AAD authentication types in order to authenticate the application.
        // If you have set the environment variables AZURE_CLIENT_ID, AZURE_TENANT_ID and either AZURE_CLIENT_SECRET or AZURE_CLIENT_CERTIFICATE_PATH it will use this.
        DefaultAzureCredential credential = new DefaultAzureCredentialBuilder().build();

        System.out.println("Storage Account Table access with AAD");
        System.out.println("Using endpoint: " + endPoint);

        // Now, let's add a table, and add a record
        try
        {

            // Set a table name
            final String tableName = "Employees";


            // Create a TableServiceClient and feed it our credential object
            TableServiceClient tableServiceClient = new TableServiceClientBuilder()
                .credential(credential)
                .endpoint(endPoint)
                .buildClient();

            // Create the table if it not exists.
            TableClient tableClient;

            System.out.println("Creating table " + tableName + " unless it already exists");
            tableClient = tableServiceClient.createTableIfNotExists(tableName);

            // if the Table already exists, then poing tableClient at it 
            if (null == tableClient) {
                tableClient = tableServiceClient.getTableClient(tableName);
            }
            

            // Create a new employee TableEntity.
            String partitionKey = "Sales";
            String rowKey = "0001";
            Map<String, Object> personalInfo= new HashMap<>();
            personalInfo.put("FirstName", "Walter");
            personalInfo.put("LastName", "Harp");
            personalInfo.put("Email", "Walter@contoso.com");
            personalInfo.put("PhoneNumber", "425-555-0101");
            TableEntity employee = new TableEntity(partitionKey, rowKey).setProperties(personalInfo);
            
            System.out.println(String.format("Creating entity with partitionKey %s and rowKey %s", partitionKey, rowKey));
            // Upsert the entity into the table
            tableClient.upsertEntity(employee);


        }
        catch (Exception e)
        {
            // Output the stack trace.
            e.printStackTrace();
        }

    



    }
}