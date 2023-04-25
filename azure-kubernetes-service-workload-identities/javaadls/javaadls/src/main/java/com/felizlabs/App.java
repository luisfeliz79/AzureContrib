package com.felizlabs;

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import com.azure.identity.*;

import com.azure.storage.file.datalake.DataLakeDirectoryClient;
import com.azure.storage.file.datalake.DataLakeFileClient;
import com.azure.storage.file.datalake.DataLakeFileSystemClient;
import com.azure.storage.file.datalake.DataLakeServiceClient;
import com.azure.storage.file.datalake.DataLakeServiceClientBuilder;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This example shows how to start using the Azure Storage Data Lake SDK for Java.
 */
public class App {

    /**
     * Entry point into the basic examples for Storage datalake.
     *
     * @param args Unused. Arguments to the program.
     * @throws IOException If an I/O error occurs
     * @throws RuntimeException If the downloaded data doesn't match the uploaded data
     */
    public static void main(String[] args) throws IOException {

        Logger logger = LoggerFactory.getLogger(App.class);

        // The storage account name
        String accountName = System.getenv("JAVAADLS_STORAGEACCT_NAME");
        logger.info(String.format(Locale.ROOT,"Using Storage account Name: %s",accountName));
        // Get the Managed Identity Client ID from environment variables
        String client_id=System.getenv("AZURE_CLIENT_ID");
        


        // This will create a ChainedTokenCredential which will try managed identites first,
        // followed by AZ CLI login credential
        // This approach speeds up token acquisition by bypassing uneneeded login types
        logger.info("Attempting to get a token...");
        ManagedIdentityCredential managedIdentityCred = new ManagedIdentityCredentialBuilder().clientId(client_id).build();
        AzureCliCredential azCliCred = new AzureCliCredentialBuilder().build();
        
        ChainedTokenCredential credential = 
            new ChainedTokenCredentialBuilder()
                .addFirst(managedIdentityCred)
                .addLast(azCliCred)
                .build();

        /*
         * From the Azure portal, get your Storage account dfs service URL endpoint.
         * The URL typically looks like this:
         */
        String endpoint = String.format(Locale.ROOT, "https://%s.dfs.core.windows.net", accountName);

        /*
         * Create a DataLakeServiceClient object that wraps the service endpoint, credential and a request pipeline.
         */
        DataLakeServiceClient storageClient = new DataLakeServiceClientBuilder().endpoint(endpoint).credential(credential).buildClient();

        /*
         * This example shows several common operations just to get you started.
         */

        /*
         * Create a client that references a to-be-created file system in your Azure Storage account. This returns a
         * FileSystem object that wraps the file system's endpoint, credential and a request pipeline (inherited from storageClient).
         * Note that file system names require lowercase.
         */
        DataLakeFileSystemClient dataLakeFileSystemClient = storageClient.getFileSystemClient("myjavafilesystembasic" + System.currentTimeMillis());

        /*
         * Create a file system in Storage datalake account.
         */
        dataLakeFileSystemClient.create();

        /*
         * Create a directory in the filesystem
         */
        DataLakeDirectoryClient directoryClient = dataLakeFileSystemClient.createDirectory("myDirectory");

        /*
         * Create a file and sub directory in the directory
         */
        DataLakeFileClient fileUnderDirectory = directoryClient.createFile("myFileName");
        DataLakeDirectoryClient subDirectory = directoryClient.createSubdirectory("mySubDirectory");

        logger.info("File under myDirectory is " + fileUnderDirectory.getFileName());
        logger.info("Directory under myDirectory is " + subDirectory.getDirectoryName());


        /*
         * Create a client that references a to-be-created file in your Azure Storage account's file system.
         * This returns a DataLakeFileClient object that wraps the file's endpoint, credential and a request pipeline
         * (inherited from dataLakeFileSystemClient). Note that file names can be mixed case.
         */
        DataLakeFileClient fileClient = dataLakeFileSystemClient.getFileClient("HelloWorld.txt");

        String data = "Hello world!";
        InputStream dataStream = new ByteArrayInputStream(data.getBytes(StandardCharsets.UTF_8));

        /*
         * Create the file with string (plain text) content.
         */
        fileClient.create(true);
        fileClient.append(dataStream, 0, data.length());
        fileClient.flush(data.length(),true);
        dataStream.close();

        /*
         * Download the file's content to output stream.
         */
        int dataSize = (int) fileClient.getProperties().getFileSize();
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream(dataSize);
        fileClient.read(outputStream);
        outputStream.close();

        /*
         * Verify that the file data round-tripped correctly.
         */
        if (!data.equals(new String(outputStream.toByteArray(), StandardCharsets.UTF_8))) {
            throw new RuntimeException("The downloaded data does not match the uploaded data.");
        }

        /*
         * Create more files (maybe even a few directories) before listing.
         */
        for (int i = 0; i < 3; i++) {
            String sampleData = "Samples";
            InputStream dataInFiles = new ByteArrayInputStream(sampleData.getBytes(Charset.defaultCharset()));
            DataLakeFileClient fClient = dataLakeFileSystemClient.getFileClient("myfilesforlisting" + System.currentTimeMillis());
            fClient.create();
            fClient.append(dataInFiles, 0, sampleData.length());
            fClient.flush(sampleData.length(),true);
            dataInFiles.close();
            dataLakeFileSystemClient.getDirectoryClient("mydirsforlisting" + System.currentTimeMillis()).create();
        }

        /*
         * List the path(s) in our file system.
         */
        dataLakeFileSystemClient.listPaths()
            .forEach(pathItem -> logger.info("Path name: " + pathItem.getName()));

        /*
         * Delete the file we created earlier.
         */
        //fileClient.delete();

        /*
         * Delete the file system we created earlier.
         */
        //dataLakeFileSystemClient.delete();

          // Let's spin up a web server on port 80 so that we can
          // properly run this as an Azure Kubernetes Service deployment
          // or an App Service container
          logger.info("Starting the web server");
          WebUI myWebUI = new WebUI("OK");
          myWebUI.start();
          logger.info ("Started");
    }
}
