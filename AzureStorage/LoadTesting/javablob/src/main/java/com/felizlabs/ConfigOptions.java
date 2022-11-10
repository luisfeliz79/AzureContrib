package com.felizlabs;

import java.net.InetAddress;
import java.time.Duration;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.Files;

import com.google.gson.Gson;

import java.io.IOException;

import java.net.UnknownHostException;

  // Read configuration options from file or use defaults
public class ConfigOptions {
   
    Duration timeout;            // Default: 60                  - if a BlobClient operation is taking too long, this is the time out
                                 
    String containerName;        // Default: testdata            - the container name in the storage account               
    String storageBlobEndpoint;  // No Default                   - Https URL of the storage account blob endpoint
    String hostname;             // Default: Auto populated      - Automatically populated from the running instance
    Integer numberOfDownloads;   // Default: 10                  - The GetBlob operation will run this many times
    String webUIEnabled;

    public ConfigOptions(){
  
      // First try to read settings from file
      Path configFilePath = Paths.get("javablob.config");
      TestOptions options = new TestOptions();
  
      try {
        
        String configFileJson = Files.readString(configFilePath);
        
        Gson configOptions = new Gson();
        options = configOptions.fromJson(configFileJson,TestOptions.class);
     
      } catch (IOException e) {
        System.out.println("Did not find "+configFilePath.toAbsolutePath());
        
      }
  
      // Next check for environmental variables
      try {

        if (System.getenv("storageBlobEndpoint") != null ) {
          options.storageBlobEndpoint = System.getenv("storageBlobEndpoint");          
        }

      } catch (NullPointerException badEnv) {

      }

      try {
        if (System.getenv("numberOfDownloads") != null ) {
          options.numberOfDownloads = Integer.parseInt((System.getenv("numberOfDownloads")));
        }

      } catch (NumberFormatException badInt) {
          System.out.println("numberOfDownloads environment variable does not contain a valid number");
      } catch (NullPointerException badEnv2) {

      }

      try {

        if (System.getenv("containerName") != null ) {
          options.containerName = System.getenv("containerName");
        }

      } catch (NullPointerException badEnv) {

      }

      try {

        if (System.getenv("webUIEnabled") != null ) {
          options.webUIEnabled =  System.getenv("webUIEnabled");
        }

      } catch (NullPointerException badEnv) {

      }

     // populate the settings



      // Timeout for BlobClient operations
      timeout = (options.timeoutValue == null) ? Duration.ofSeconds(60) : Duration.ofSeconds(options.timeoutValue);
  
  
      // The container name where to list and get blobs
      containerName = (options.containerName == null) ? "testdata" : options.containerName;       
     
      // The storage account endpoint
      if ( null == options.storageBlobEndpoint) {
        System.out.println("Error: storageBlobEndpoint was not specified in either an environment variable or " + configFilePath.toAbsolutePath());
        System.exit(1);
      } else {
         storageBlobEndpoint = options.storageBlobEndpoint;
      }
      
      // number of blobs to get during each test
      numberOfDownloads = (options.numberOfDownloads == null) ? 10 : options.numberOfDownloads;
  
      // Enable or Disable the WebUI
      webUIEnabled = (options.webUIEnabled == null) ? "true" : options.webUIEnabled;

      // Get hostname
      try {
        InetAddress inetadd = InetAddress.getLocalHost();
        hostname = inetadd.getHostName();      
      }  catch(UnknownHostException u){
        hostname = "<NameNotAvailable>";
      }
  
      
  
    }
  }


  
// TestOptions class 
class TestOptions {
    Long timeoutValue;
    String containerName;       
    String storageBlobEndpoint;
    String hostname;
    Integer numberOfDownloads;
    String webUIEnabled;
  }
  