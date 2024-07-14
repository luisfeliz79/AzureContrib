// This is a simple Java application that demonstrates how to authenticate, upload, list, and download blobs from an Azure Storage Account
// https://github.com/luisfeliz79/AzureContrib/azure-storage-sdk-samples

// For instructions see 

package com.felizlabs;

// for working with Blobs
import com.azure.identity.*;
import com.azure.storage.blob.*;
import com.azure.storage.blob.models.*;
import com.azure.core.http.rest.PagedIterable;


// Supporting libraries
import com.azure.core.util.BinaryData;
import java.io.File;

// for Logger
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// This is very simple sample to show how to authenticate, 
// upload, list, download blobs from an Azure Storage Account

// This sample is based on documentation and other examples found here:
// https://learn.microsoft.com/en-us/java/api/overview/azure/storage-blob-readme?view=azure-java-stable#examples
// Async version: https://learn.microsoft.com/en-us/java/api/com.azure.storage.blob.blobasyncclient?view=azure-java-stable

public class App 
{

    // Using Logback for logging 
    public static Logger logger = LoggerFactory.getLogger(App.class);
    
    public static void main( String[] args )
    {
        
        // Specify the storage account name and container name       
        String accountName             = "<the storage account name (not the fqdn)>";
        String container               = "<the name of a container>";


        // Variables used by the sample
        String sampleUploadBlob        = "sample-file.txt";
        String sampleDownloadBlob      = "sample-file.txt";
        String localDestinationPath    = "downloaded-files";

        // Define a DefaultAzureCredential object to authenticate with the Azure Storage account
        // This authentication method will try serveral methods to authenticate,
        // including the logged in user, Managed Identity, Service principal via Environment Variables, and Visual Studio Code authentication
        // To learn more, see here: https://learn.microsoft.com/en-us/java/api/overview/azure/identity-readme?view=azure-java-stable#defaultazurecredential
        
        DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder().build();
       
        // If using a User Assigned Managed Identity, you can specify the client ID
        // DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()
        //     .managedIdentityClientId("<MANAGED_IDENTITY_CLIENT_ID aka APPID>")
        //     .build();

            

        // Container Client builder
        // For operations within a container such as list, upload, download, more...
        // REF: https://learn.microsoft.com/en-us/java/api/overview/azure/storage-blob-readme?view=azure-java-stable
        
        BlobContainerClient blobContainerClient = new BlobContainerClientBuilder()
            .endpoint("https://" + accountName + ".blob.core.windows.net/")
            .credential(defaultCredential)
            .containerName(container)
            .buildClient();

        System.out.println(String.format("Starting app... Using Storage Account %s and container %s",accountName,container) );
        
        // Sample for Uploading a Blob
        UploadBlobExample(blobContainerClient,container,sampleUploadBlob);

        // Sample for Listing Blobs
        ListBlobsExample(blobContainerClient,container);

        // Sample for Downlaoding a single Blob
        DownloadBlobExample(blobContainerClient, container, sampleDownloadBlob,localDestinationPath);
        
        // Sample for Downloading all Blobs
        // DownloadAllExample(blobContainerClient, container);

    }

    // Sample function that uploads a single blob from file
    public static void UploadBlobExample(BlobContainerClient blobContainerClient, String container, String blobName) {
        // REF: https://learn.microsoft.com/en-us/java/api/overview/azure/storage-blob-readme?view=azure-java-stable#upload-data-to-a-blob
        //      https://learn.microsoft.com/en-us/java/api/com.azure.storage.blob.blobclient?view=azure-java-stable#com-azure-storage-blob-blobclient-uploadfromfile(java-lang-string)        

        
        try {
            System.out.println(String.format("Uploading %s ...",blobName) );
            BlobClient blobClient = blobContainerClient.getBlobClient(blobName);
            blobClient.uploadFromFile(blobName,true);
            System.out.println("SUCCESS: Blob uploaded");

            // Other methods - upload from memory
            // String dataSample = "This data will be saved to a blob";
            // blobClient.upload(BinaryData.fromString(dataSample));



        } catch (Exception e) {
            System.out.println("Error uploading blob");
            System.out.println(e.getMessage());
        }

    }

    // Sample function that List Blobs
    public static void ListBlobsExample(BlobContainerClient blobContainerClient, String container) {

        // REF: https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-list-java


        String blobName;

        System.out.println(String.format("Listing contents of /%s",container));

        PagedIterable<BlobItem> pagedIterable = blobContainerClient.listBlobs();

        java.util.Iterator<BlobItem> iterator = pagedIterable.iterator();
   
        BlobItem item = iterator.next();
    
        while (item != null)
        {
            blobName = item.getName();
            System.out.println(String.format("  /%s",blobName));

            if (!iterator.hasNext())
            {
                break;
            }
            item = iterator.next();
        }
        
    }


    
    // Sample function Downloads a single blob
    public static void DownloadBlobExample(BlobContainerClient blobContainerClient, String container, String blobName, String destinationPath) {
        
        // REF: https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-download-java

        // Use an output filename that matches the blob file name
        String outputFileName = String.format("%s\\%s",
                destinationPath,    
                blobName.substring(blobName.lastIndexOf("/")+ 1)
            );

        try {

            System.out.println(String.format("Downloading %s to %s ...",outputFileName, destinationPath) );

            BlobClient blobClient = blobContainerClient.getBlobClient(blobName);

            //  Several Download options are:

            //  Download the blob to a file
                blobClient.downloadToFile(outputFileName,true);

            //  Download the blob to memory (ex a string)
                // String content = blobClient.downloadContent().toString();  

            //  Stream the blob 
                // ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
                // blobClient.downloadStream(outputStream);
        
                System.out.println("SUCCESS: Blob downloaded");
        
        } catch (Exception e) {
            System.out.println("Error downloading blob");
            System.out.println(e.getMessage());
        }
        

    }

    // Sample function that Downloads all blobs in a container with directory structure
    public static void DownloadAllExample(BlobContainerClient blobContainerClient, String container) {

        String blobName;        

        PagedIterable<BlobItem> pagedIterable = blobContainerClient.listBlobs();

        java.util.Iterator<BlobItem> iterator = pagedIterable.iterator();
   
        BlobItem item = iterator.next();
    
        while (item != null)
        {
            blobName = item.getName();
            
            // First create the directory structure
            String parentDir = LocalDirectoryCreator(blobName);

            DownloadBlobExample(blobContainerClient, container, blobName,parentDir);
            

            // take in the path name for a file and create the directory strucuture for that path name, but only if the folder doesnt already exist
            if (!iterator.hasNext())
            {
                break;
            }
            item = iterator.next();
        }
        
    }

    // Sample helper function that creates a directory structure based on a path
    public static String LocalDirectoryCreator(String directoryPath) {
        
        String currentDirectory = System.getProperty("user.dir");

        // Split the input string by the directory separator ("/" in this case)
        File file = new File(directoryPath);
        String parentDirectoryPath = file.getParent();


        String[] directories = parentDirectoryPath.split("\\\\");

        // Create each directory in the structure
        for (String dir : directories) {
            currentDirectory += String.format("%s%s",File.separator,dir);
            File newDir = new File(currentDirectory);
            if (!newDir.exists()) {
                if (newDir.mkdir()) {
                    System.out.println("Created directory: " + newDir.getAbsolutePath());
                } else {
                    System.err.println("Failed to create directory: " + newDir.getAbsolutePath());
                }
            }
        }

        return parentDirectoryPath;
    }

}


