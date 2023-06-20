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
    private boolean UseAzureStorage = true;

    // Program constants
    private String STORAGE_ACCOUNT_DATA_CONTAINER = "appinsightsdemo-data";
    private String dataPath = "data";
    private String tmpPath = "tmp";

    public ProcessJob(JobDefinition Job,CustomTelemetry telemetry) {
        
        // Constructor               
        this.STORAGE_ACCOUNT_NAME = System.getenv("STORAGE_ACCOUNT_NAME");
        this.logger = telemetry.logger;
        this.telemetry = telemetry;
        String fileName1 = Job.getfileName1();
        String fileName2 = Job.getfileName2();
        String jobName = Job.getjobName();

        // Check for AD LS required environment variables
        // If any of these are missing, then report it, and do not use Azure Storage
        if (null == STORAGE_ACCOUNT_NAME  ) {logger.info("Missing Variable STORAGE_ACCOUNT_NAME"); this.UseAzureStorage = false;}
        if (null == System.getenv("AZURE_CLIENT_ID"))              {logger.info("Missing Variable AZURE_CLIENT_ID"); this.UseAzureStorage = false;}
        if (null == System.getenv("AZURE_CLIENT_SECRET")  )        {logger.info("Missing Variable AZURE_CLIENT_SECRET"); this.UseAzureStorage = false;}
        if (null == System.getenv("AZURE_TENANT_ID")  )            {logger.info("Missing Variable AZURE_TENANT_ID"); this.UseAzureStorage = false;}

        // Check if folder exists, otherwise create it
        File dir = new File(tmpPath);
        if (!dir.exists()) {
            logger.info("Creating data folder "+tmpPath);
            dir.mkdirs();
        }
        
        
    

        // Kick off the process

        if (this.UseAzureStorage) {

            logger.info("Using Azure Storage. Speed and transfer times will be reported");

            // The first time we use the storage account, we have to upload some data files
            PrepareStorageAccountForDemo();

            // Now begin the Job process
            // First, download needed data files
            String workFile1 = DownloadADLSFile(fileName1, jobName);
            String workFile2 = DownloadADLSFile(fileName2, jobName);

            // Use the data files to create a merged file
            String mergedFile = CreatePassPhraseList(workFile1, workFile2, jobName);

            // Upload the resulting file       
            UploadADLSFile(mergedFile, jobName);

            logger.info("Merged file is "+mergedFile);


        } else {

            logger.info("Using Local Storage. Only lines read will be reported");

            // Use local Storage
            String workFile1 = String.format ("%s/%s",dataPath,fileName1);
            String workFile2 = String.format ("%s/%s",dataPath,fileName2);

            // Use the data files to create a merged file
            String mergedFile = CreatePassPhraseList(workFile1, workFile2, jobName);

            logger.info("Merged file is "+mergedFile);
        }
        
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

        Path path = Paths.get(fileName);
        long size=(long)0;
        try {
            size = Files.size(path);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        logger.info(String.format("size:%s",size));

        fileClient.uploadFromFile(fileName, true);
     
        long timeTaken = System.nanoTime()-start;
        long timeTakenInSecs=timeTaken/1000000000;
        long speed=(long)0;
        if (timeTakenInSecs > 0) {
            speed     = (size/1024/1024) / timeTakenInSecs ;
        } else {
            // Transfer took less than one second, so just use the size as the speed
            speed = (size/1024/1024);
        }

        logger.info (String.format("Transfer took %s seconds at speed %sMB/s - file size %s bytes",timeTakenInSecs,speed,size));
        telemetry.TrackWriteSpeed(speed);
        telemetry.TrackWriteTransferTime(timeTakenInSecs);
        logger.info("Completed Upload");
    }
    public String DownloadADLSFile(String fileName, String jobName) {

        
        // Define Credentials
        DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()        
        .build();

        // Create the client
        String endpoint = String.format( "https://%s.dfs.core.windows.net", this.STORAGE_ACCOUNT_NAME);


        DataLakeServiceClient storageClient = new DataLakeServiceClientBuilder()
                                                    .endpoint(endpoint)
                                                    .credential(defaultCredential)
                                                    .buildClient();

        DataLakeFileSystemClient dataLakeFileSystemClient = storageClient.getFileSystemClient(STORAGE_ACCOUNT_DATA_CONTAINER);


        // Create file client
        DataLakeFileClient fileClient = dataLakeFileSystemClient.getFileClient(fileName);
        
        // Define the local filenames
        String fileDownloadTo = String.format("%s/work-%s",tmpPath,fileName);

        logger.info(String.format("Download File %s to %s ...",fileName,fileDownloadTo));
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
        long speed=(long)0;
        if (timeTakenInSecs > 0) {
            speed     = (size/1024/1024) / timeTakenInSecs ;
        } else {
            // Transfer took less than one second, so just use the size as the speed
            speed = (size/1024/1024);
        }

        logger.info (String.format("Transfer took %s seconds at speed %sMB/s - file size %s bytes",timeTakenInSecs,speed,size));
        telemetry.TrackReadSpeed(speed);
        telemetry.TrackReadTransferTime(timeTakenInSecs);
        logger.info("Completed Download");

        return fileDownloadTo;

    }

    public String CreatePassPhraseList(String wordList1,String wordList2,String jobName)  {

        Scanner file1;
        Scanner file2;
 
        logger.info(String.format("Merging %s and %s, this can take a few minutes ...",wordList1,wordList2));
        
        try {
             file1 = new Scanner (new File(wordList1));
             file2 = new Scanner (new File(wordList2));
 
             String newLine = System.lineSeparator();
             String jobFile = String.format("%s/%s-output.txt",tmpPath,jobName);
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

             return jobFile;

             
         } catch (IOException e) {
             // TODO Auto-generated catch block
             e.printStackTrace();
             return "<error-could-not-complete>";
         }
        
         
         
     }

     public void PrepareStorageAccountForDemo  () {

        // Define Credentials
        DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()        
        .build();

        // Create the client
        String endpoint = String.format( "https://%s.dfs.core.windows.net", this.STORAGE_ACCOUNT_NAME);


        DataLakeServiceClient storageClient = new DataLakeServiceClientBuilder()
                                                    .endpoint(endpoint)
                                                    .credential(defaultCredential)
                                                    .buildClient();

        DataLakeFileSystemClient dataLakeFileSystemClient = storageClient.getFileSystemClient(STORAGE_ACCOUNT_DATA_CONTAINER);

        // Checks if the file system already exists
        if (dataLakeFileSystemClient.exists()) {
            // If the container already exist, assume this storage account is already prepared
            logger.info("Storage account data found");                 

        } else {
            //Otherwise Create the filesystem and upload data files
            logger.info("Storage account data being uploaded...");
            dataLakeFileSystemClient.create();
            // Create a fileclient
            // Get a list of files from directory
            File dir = new File("data");
            File[] directoryListing = dir.listFiles();
            if (directoryListing != null) {
                for (File child : directoryListing) {
                    String fileName = child.getName();
                    //String fileNameWithPath = String.format("%s/%s",STORAGE_ACCOUNT_DATA_CONTAINER,fileName);
                    DataLakeFileClient fileClient = dataLakeFileSystemClient.getFileClient(fileName);
                    fileClient.uploadFromFile(dataPath+"/"+fileName, true);

                }
            } else {
                logger.info("No files found in data directory");
            }

            logger.info("Storage account data upload complete");

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
