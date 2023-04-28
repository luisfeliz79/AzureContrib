package com.felizlabs.samples.telemetrytagging;

import java.io.BufferedWriter;
// General
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Scanner;

// for logging
import org.slf4j.Logger;

// For AD LS Storage
import com.azure.identity.*;
import com.azure.storage.file.datalake.DataLakeFileClient;
import com.azure.storage.file.datalake.DataLakeFileSystemClient;
import com.azure.storage.file.datalake.DataLakeServiceClient;
import com.azure.storage.file.datalake.DataLakeServiceClientBuilder;

public class ProcessJob {

    private String STORAGE_ACCOUNT_NAME;
    private Logger logger;
    private CustomTelemetry telemetry;

    public ProcessJob(JobDefinition Job,CustomTelemetry telemetry) {
        
        // Constructor               
        this.STORAGE_ACCOUNT_NAME = System.getenv("STORAGE_ACCOUNT_NAME");
        this.logger = telemetry.logger;
        this.telemetry = telemetry;

        // Check for AD LS required environment variables
        if (null == STORAGE_ACCOUNT_NAME  ) {logger.info("Missing Variable STORAGE_ACCOUNT_NAME"); System.exit(0);}
        if (null == System.getenv("AZURE_CLIENT_ID"))            {logger.info("Missing Variable AZURE_CLIENT_ID"); System.exit(0);}
        if (null == System.getenv("AZURE_CLIENT_SECRET")  )        {logger.info("Missing Variable AZURE_CLIENT_SECRET"); System.exit(0);}
        if (null == System.getenv("AZURE_TENANT_ID")  )            {logger.info("Missing Variable AZURE_TENANT_ID"); System.exit(0);}

        String fileName1 = Job.getfileName1();
        String fileName2 = Job.getfileName2();
        String jobName = Job.getjobName();


        // Kick off the process

            // Create a large file (about 256MB)
            CreatePassPhraseList(fileName1, fileName2, jobName);

            // Upload and Download to a Storage account for emulation purposes
            String jobFile = String.format("%s-output.txt",jobName);           
            UploadADLSFile(jobFile, jobName);
            DownloadADLSFile(jobFile, jobName);

            // Now Sit and wait a 2 minutes for better JVM metrics telemetry
            JustSitAndWait(120);
        
    }
    
    public void UploadADLSFile  (String fileName, String jobName) {

        // Define Credentials
        DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()        
        .build();

        // Create the client
        String endpoint = String.format( "https://%s.dfs.core.windows.net", this.STORAGE_ACCOUNT_NAME);


        DataLakeServiceClient storageClient = new DataLakeServiceClientBuilder()
                                                    .endpoint(endpoint)
                                                    .credential(defaultCredential)
                                                    .buildClient();

        DataLakeFileSystemClient dataLakeFileSystemClient = storageClient.getFileSystemClient(jobName);

        // Checks if the file system already exists
        if (!dataLakeFileSystemClient.exists()) {            
                // Create the filesystem
                dataLakeFileSystemClient.create();
        }

        // Create the Directory
        String dirName = "test";
        if (!dataLakeFileSystemClient.getDirectoryClient(dirName).exists()) {
            dataLakeFileSystemClient.createDirectory(dirName);
        }

        // Create a fileclient
        String fileNameWithPath = String.format("%s/%s",dirName,fileName);
        DataLakeFileClient fileClient = dataLakeFileSystemClient.getFileClient(fileNameWithPath);

        
        

        logger.info("Uploading File ...");
        long start = System.nanoTime();

        Path path = Paths.get("tmp/"+fileName);
        long size=(long)0;
        try {
            size = Files.size(path);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        logger.info(String.format("size:%s",size));

        fileClient.uploadFromFile("tmp/"+fileName, true);
     
        long timeTaken = System.nanoTime()-start;
        long timeTakenInSecs=timeTaken/1000000000;
        long speed     = (size/1024/1024) / timeTakenInSecs ;

        logger.info (String.format("Transfer took %s seconds at speed %sMB/s - file size %s bytes",timeTakenInSecs,speed,size));
        telemetry.TrackWriteSpeed(speed);
        telemetry.TrackWriteTransferTime(timeTakenInSecs);
        logger.info("Completed Upload");



    }
    public void DownloadADLSFile(String fileName, String jobName) {

        
        // Define Credentials
        DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()        
        .build();

        // Create the client
        String endpoint = String.format( "https://%s.dfs.core.windows.net", this.STORAGE_ACCOUNT_NAME);


        DataLakeServiceClient storageClient = new DataLakeServiceClientBuilder()
                                                    .endpoint(endpoint)
                                                    .credential(defaultCredential)
                                                    .buildClient();

        DataLakeFileSystemClient dataLakeFileSystemClient = storageClient.getFileSystemClient(jobName);

        // // Create the filesystem client
        // try {
        //     dataLakeFileSystemClient.create();
        //     logger.info (String.format("Container %s created",jobName));
        // } catch (DataLakeStorageException error) {
        //     //if (error.getErrorCode().equals(BlobErrorCode.CONTAINER_ALREADY_EXISTS)) {
        //         logger.info(String.format("Container %s already exists",jobName));
        //     //}
        // }

        // Create the Directory
        String dirName = "test";
        //DataLakeDirectoryClient directoryClient = dataLakeFileSystemClient.getDirectoryClient(dirName);


        // Create a fileclient
        String fileNameWithPath= String.format("%s/%s",dirName,fileName);
        DataLakeFileClient fileClient = dataLakeFileSystemClient.getFileClient(fileNameWithPath);

        
        // Define the local filename
        String fileDownloadTo = String.format("tmp/down-%s",fileName);

        logger.info(String.format("Download File %s to %s ...",fileNameWithPath,fileDownloadTo));
        long start = System.nanoTime();

        fileClient.readToFile(fileDownloadTo,true);
        
        long size=(long)0;
        Path path = Paths.get(fileDownloadTo);
        try {
            size = Files.size(path);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        
        logger.info(String.format("size:%s",size));

        long timeTaken = System.nanoTime()-start;
        long timeTakenInSecs=timeTaken/1000000000;
        long speed     = (size/1024/1024) / timeTakenInSecs ;

        logger.info (String.format("Transfer took %s seconds at speed %sMB/s - file size %s bytes",timeTakenInSecs,speed,size));
        telemetry.TrackReadSpeed(speed);
        telemetry.TrackReadTransferTime(timeTakenInSecs);
        logger.info("Completed Download");

    }

    public void CreatePassPhraseList(String wordList1,String wordList2,String jobName)  {

        Scanner file1;
        Scanner file2;
 
        logger.info(String.format("Merging %s and %s, this can take a few minutes ...",wordList1,wordList2));
        
        try {
             file1 = new Scanner (new File(wordList1));
             file2 = new Scanner (new File(wordList2));
 
             String newLine = System.lineSeparator();
             String jobFile = String.format("tmp/%s-output.txt",jobName);
             FileWriter fstream = new FileWriter (jobFile);
             BufferedWriter outputFile = new BufferedWriter(fstream);            
 
            // Read words from first file
             while(file1.hasNext()){
 
                 String word1=file1.next();
                 //System.out.println(word1);
 
                // Read words from 2nd file
                 while (file2.hasNext()) {
                     String word2 = file2.next();

                     for (int i = 100;i<1000;i++) {
                        String mergedWords = String.format("%s%s%s%s",word1,word2,i,newLine);
                        outputFile.write(mergedWords);
                     }
 

                     
                     // This method implements a counter which counts # of lines processed                    
                     telemetry.TrackLinesRead();
 
                 }
                 
             }
             outputFile.close();
             file2.close();
             file1.close();
              
             logger.info("Completed.");

             
         } catch (IOException e) {
             // TODO Auto-generated catch block
             e.printStackTrace();
         }
        
         
     }

     public void JustSitAndWait(int HowLongInSeconds) {

        int ThisLong = 1000 * HowLongInSeconds;

        logger.info(String.format("Waiting %s seconds for emulation purpuses...",HowLongInSeconds));

                try {
                    Thread.sleep(ThisLong);
                } catch (InterruptedException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }

     }
    
}
