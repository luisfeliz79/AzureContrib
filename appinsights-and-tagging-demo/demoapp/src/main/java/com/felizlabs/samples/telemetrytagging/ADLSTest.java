package com.felizlabs.samples.telemetrytagging;

// General
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Scanner;

// for logging
import org.slf4j.Logger;

// For AD LS Storage
import com.azure.identity.*;
import com.azure.storage.file.datalake.DataLakeDirectoryClient;
import com.azure.storage.file.datalake.DataLakeFileClient;
import com.azure.storage.file.datalake.DataLakeFileSystemClient;
import com.azure.storage.file.datalake.DataLakeServiceClient;
import com.azure.storage.file.datalake.DataLakeServiceClientBuilder;
import com.azure.storage.file.datalake.models.DataLakeStorageException;




public class ADLSTest {

    private String STORAGE_ACCOUNT_NAME;
    private Logger logger;
    private CustomTelemetry telemetry;

    public ADLSTest(String fileName, String jobName,CustomTelemetry telemetry) {
        
        // Constructor               
        this.STORAGE_ACCOUNT_NAME = System.getenv("STORAGE_ACCOUNT_NAME");
        this.logger = telemetry.logger;
        this.telemetry = telemetry;

        // Check for AD LS required environment variables
        if (null == STORAGE_ACCOUNT_NAME  ) {logger.info("Missing Variable STORAGE_ACCOUNT_NAME"); System.exit(0);}
        if (null == System.getenv("AZURE_CLIENT_ID"))            {logger.info("Missing Variable AZURE_CLIENT_ID"); System.exit(0);}
        if (null == System.getenv("AZURE_CLIENT_SECRET")  )        {logger.info("Missing Variable AZURE_CLIENT_SECRET"); System.exit(0);}
        if (null == System.getenv("AZURE_TENANT_ID")  )            {logger.info("Missing Variable AZURE_TENANT_ID"); System.exit(0);}

        // Kick off the process     
        UploadADLSFile(fileName, jobName);
        DownloadADLSFile(fileName, jobName);
        ProcessData(fileName);
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

        // Create the filesystem
        try {
            dataLakeFileSystemClient.create();
            logger.info (String.format("Container %s created",jobName));
        } catch (DataLakeStorageException error) {
                logger.info(String.format("Container %s already exists",jobName));
        }

        // Create the Directory
        String dirName = "test";
        DataLakeDirectoryClient directoryClient = dataLakeFileSystemClient.createDirectory(dirName);


        // Create a fileclient
        String fileNameWithPath= String.format("%s/%s",dirName,fileName);
        DataLakeFileClient fileClient = dataLakeFileSystemClient.getFileClient(fileNameWithPath);

        
        

        logger.info("Uploading File ...");
        long start = System.nanoTime();

        Path path = Paths.get("data/"+fileName);
        long size=(long)0;
        try {
            size = Files.size(path);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        logger.info(String.format("size:%s",size));

        fileClient.uploadFromFile("data/"+fileName, true);
     
        long timeTaken = System.nanoTime()-start;
        long timeTakenInSecs=timeTaken/1000000000;
        long speed     = (size/1024/1024) / timeTakenInSecs ;

        logger.info (String.format("Transfer took %s seconds at speed %sMB/s - file size %s bytes",timeTakenInSecs,speed,size));
        telemetry.TrackWriteSpeed(speed);
        telemetry.TrackWriteTransferTime(timeTakenInSecs);
        logger.info("Completed");



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

        // Create the filesystem
        try {
            dataLakeFileSystemClient.create();
            logger.info (String.format("Container %s created",jobName));
        } catch (DataLakeStorageException error) {
            //if (error.getErrorCode().equals(BlobErrorCode.CONTAINER_ALREADY_EXISTS)) {
                logger.info(String.format("Container %s already exists",jobName));
            //}
        }

        // Create the Directory
        String dirName = "test";
        DataLakeDirectoryClient directoryClient = dataLakeFileSystemClient.getDirectoryClient(dirName);


        // Create a fileclient
        String fileNameWithPath= String.format("%s/%s",dirName,fileName);
        DataLakeFileClient fileClient = dataLakeFileSystemClient.getFileClient(fileNameWithPath);

        
        // Define the local filename
        String fileDownloadTo = String.format("temp-%s",fileName);

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
        logger.info("Completed");

    }

    public void ProcessData (String fileName) {


        String fileToScan = String.format("temp-%s",fileName);

        Scanner file;

        try {
            file = new Scanner (new File(fileToScan));
            logger.info("Scanning ...");

            while(file.hasNext()){
                String word=file.next();
                telemetry.TrackLinesRead();
            }
            file.close();
        logger.info("Completed.");
        } catch (FileNotFoundException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        
    }
    
}
