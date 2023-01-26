package com.felizlabs;

import com.azure.core.util.BinaryData;
import com.azure.identity.*;
import com.azure.storage.blob.*;
import com.azure.storage.blob.models.BlobItem;
import com.azure.storage.blob.models.BlobListDetails;
import com.azure.storage.blob.models.BlobStorageException;
import com.azure.storage.blob.models.ListBlobsOptions;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Random;




public class MultiThreadApp 
{

    

    public static void main( String[] args ) throws InterruptedException
    {

      // Get some basic info about the instance
      // and Init the logging system
      Logger realLogger = LoggerFactory.getLogger(MultiThreadApp.class);
      MultiLogger logger = new MultiLogger(realLogger);

      // Read configuration values      
      ConfigOptions instanceConfig = new ConfigOptions();

      logger.info ("Instance begins, target is "+instanceConfig.storageBlobEndpoint);

      // Start the WebUI if enabled
      if (instanceConfig.webUIEnabled == "true") {
        WebUI myWebUI = new WebUI(logger);
        myWebUI.start();
      }

      // The default credential first checks environment variables for configuration
      // If environment configuration is incomplete, it will try managed identity
      //
      // run az login for testing in development onprem

      //DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder().build();

      // This will create a ChainedTokenCredential which will try managed identites first,
      // followed by AZ CLI login credential
      // This approach speeds up token acquisition by bypassing uneneeded login types
      ManagedIdentityCredential miCred = new ManagedIdentityCredentialBuilder().build();
      AzureCliCredential azCliCred = new AzureCliCredentialBuilder().build();
      
      ChainedTokenCredential defaultCredential = 
          new ChainedTokenCredentialBuilder()
              .addFirst(miCred)
              .addLast(azCliCred)
              .build();

      //Creates the Blob Service and clients using the Storage account endpoint
      BlobServiceClient blobServiceClient = new BlobServiceClientBuilder()
        .endpoint(instanceConfig.storageBlobEndpoint)
        .credential(defaultCredential)        
        .buildClient();
    


      BlobContainerClient blobContainerClient = blobServiceClient.getBlobContainerClient(instanceConfig.containerName);
      BlobClient blobClient = blobContainerClient.getBlobClient("dummy");

      // Defines options for ListBlob, including retrieve versions
      // If you have 10 files, and 3 versions of each, then that's 30 results
      ListBlobsOptions lbOptions = 
            new ListBlobsOptions()
                .setDetails(new BlobListDetails().setRetrieveVersions(true));

      
      // List one entry to start Token acquisition
      LocalDateTime startTime = LocalDateTime.now();
      try {
      String initialBlobList=blobContainerClient.listBlobs(lbOptions,instanceConfig.timeout)
                                                .iterator()
                                                .next()
                                                .getName();
        
      } catch (BlobStorageException bError){
        logger.info("Could not read blobs from container "+instanceConfig.containerName);
        System.exit(1);
      } 
      
      LocalDateTime endTime = LocalDateTime.now();
                  
      Duration totalTime=Duration.between(startTime,endTime);
      logger.info("["+instanceConfig.hostname+"] " +"Initial operation including Token acquisition Time taken: " + totalTime.toSecondsPart() + "." + totalTime.toMillisPart() + " seconds");








      // Keeps track if a test has already ran during a timeblock
      Boolean TestFired = false;

      // Helps randomize which file to read
      Random num = new Random();

      while (true) {

        LocalDateTime fireTime = LocalDateTime.now();

        // run this test exactly at these times (every 5 minutes)
        if (fireTime.getMinute() == 0 ||
            fireTime.getMinute() == 5 ||
            fireTime.getMinute() == 10 ||
            fireTime.getMinute() == 15 ||
            fireTime.getMinute() == 20 ||
            fireTime.getMinute() == 25 ||
            fireTime.getMinute() == 30 ||
            fireTime.getMinute() == 35 ||
            fireTime.getMinute() == 40 ||
            fireTime.getMinute() == 45 ||
            fireTime.getMinute() == 50 ||
            fireTime.getMinute() == 55 
            )  {
                // Fire
                if (TestFired == false) {
                  
                  Integer downloadTimes = 0;
                  ArrayList<String> blobItemName = new ArrayList<String>();
                  TestFired = true ;
                  logger.clear();

                  //list available Blobs and versions
                  startTime = LocalDateTime.now();
                  
                                     
                  for (BlobItem blobItem : blobContainerClient.listBlobs(lbOptions,instanceConfig.timeout)) {
                    //System.out.println("\t" + blobItem.getName() +"-"+ blobItem.getVersionId());
                    blobItemName.add(blobItem.getName());                    
                  }
                  
                  endTime = LocalDateTime.now();
                  
                  totalTime=Duration.between(startTime,endTime);
                  logger.info("["+instanceConfig.hostname+"] " +"Got list of " + blobItemName.size() + " blob(s) Time taken: " + totalTime.toSecondsPart() + "."+totalTime.toMillisPart() + " seconds");

                  // start download test
                  while (downloadTimes <= instanceConfig.numberOfDownloads ) {
                                
                      downloadTimes ++;
                      Integer randomNumber = num.nextInt(blobItemName.size()-1);
                      String chosenFile = blobItemName.get(randomNumber);
                      MultiThreadedBlobAccess BlobAccess 
                                = new MultiThreadedBlobAccess(blobContainerClient,
                                                              blobClient,
                                                              lbOptions,
                                                              instanceConfig,
                                                              logger, chosenFile);
                      BlobAccess.start();
                  }
                }
                
            } else {
              TestFired = false;
            }

      } //end while


    }  // end main


} // end class




// This class is the actual test
// it is broken up into it's own class for the purposes
// of multi threading

class MultiThreadedBlobAccess extends Thread  {

  BlobContainerClient containerClient;
  BlobClient blobClient;
  ListBlobsOptions lbOptions;
  
  MultiLogger logger;

  ConfigOptions instanceConfig;

  String chosenFile;

  public MultiThreadedBlobAccess(  BlobContainerClient containerClient,
                                   BlobClient blobClient,
                                   ListBlobsOptions lbOptions,
                                   ConfigOptions instanceConfig,                                   
                                   MultiLogger logger,
                                   String chosenFile) {
      
            
            this.containerClient = containerClient;
            this.blobClient = blobClient;
            this.lbOptions = lbOptions;
            this.logger = logger;
            this.instanceConfig = instanceConfig;
            this.chosenFile = chosenFile;
  }

  public void run()
  {
        
        LocalDateTime startTime;
        LocalDateTime endTime;
        Duration totalTime;
        
        logger.info(  "[" + instanceConfig.hostname+ "] " + "Entering thread" );
        
        
        BinaryData blobData;

        //set the file name
        blobClient = containerClient.getBlobClient(chosenFile);
        
        
        startTime = LocalDateTime.now();
        // download the content into a variable
        blobData=blobClient.downloadContent();                    
        endTime = LocalDateTime.now();
        
        totalTime=Duration.between(startTime,endTime);
        logger.info(  "[" + instanceConfig.hostname+ "] " 
                          + "Downloaded " + chosenFile
                          + " (" + blobData.getLength() + " bytes"
                          + ") Time taken: " + totalTime.toSecondsPart() + "."+totalTime.toMillisPart() + " seconds"
                          );


  } // end of constructor

  

} // end of class

