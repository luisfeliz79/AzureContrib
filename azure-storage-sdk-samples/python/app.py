# Description: This script demonstrates how to upload, list and download blobs from an Azure Storage Account
# https://github.com/luisfeliz79/AzureContrib/azure-storage-sdk-samples

# For instructions, see the README.md file


import os, uuid
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient



def upload_blob(blob_service_client,container_name,blob_name):
# REF: https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python?tabs=managed-identity%2Croles-azure-portal%2Csign-in-azure-cli&pivots=blob-storage-quickstart-scratch#upload-blobs-to-a-container

    try:
        # Upload a blob to the container
        blob_file_name   = (blob_name.split("/"))[-1]
        source_file_path = blob_name

        container_client = blob_service_client.get_container_client(container= container_name) 
        print("\nUploading to blob \n\t" + blob_file_name)

        with open(source_file_path, "rb") as data:
            container_client.upload_blob(name=blob_file_name, data=data, overwrite=True)

        print ("SUCCESS:  Blob uploaded")

    except Exception as ex:
        print('Exception:')
        print(ex)

# Lists the blobs in the container
def list_blobs(blob_service_client,container_name):
# REF: https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python?tabs=managed-identity%2Croles-azure-portal%2Csign-in-azure-cli&pivots=blob-storage-quickstart-scratch#list-the-blobs-in-a-container

    try:
        # List the blobs in the container
        container_client = blob_service_client.get_container_client(container= container_name) 
        blob_list = container_client.list_blobs()
        print("\nListing blobs...")

        for blob in blob_list:
            print("\t" + blob.name)
        

    except Exception as ex:
        print('Exception:')
        print(ex)


# Downloads a blob
def download_blob(blob_service_client,container_name,blob_name):
#REF: https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python?tabs=managed-identity%2Croles-azure-portal%2Csign-in-azure-cli&pivots=blob-storage-quickstart-scratch#download-blobs
    try:
        # Download the blob to a local file
        blob_file_name   = localDestinationPath + "/" + (blob_name.split("/"))[-1]
        
        
        container_client = blob_service_client.get_container_client(container= container_name) 
        print("\nDownloading blob to  " + localDestinationPath + ": \n\t" + blob_file_name)

        with open(file=blob_file_name, mode="wb") as download_file:
            download_file.write(container_client.download_blob(blob_name).readall())
        print ("SUCCESS:  Blob downloaded")

    except Exception as ex:
        print('Exception:')
        print(ex)


###################### START ########################
if __name__=="__main__": 
        # Specify the storage account name and container name       
        accountName             = "<the storage account name (not the fqdn)>"
        container               = "<the name of a container>"


        #Variables used by the sample
        sampleUploadBlob        = "sample-file.txt"
        sampleDownloadBlob      = "sample-file.txt"
        localDestinationPath    = "downloaded-files"

        
        # Define a DefaultAzureCredential object to authenticate with the Azure Storage account
        # This authentication method will try serveral methods to authenticate,
        # including the logged in user, Managed Identity, Service principal via Environment Variables
        # To learn more, see here: https://learn.microsoft.com/en-us/python/api/azure-identity/azure.identity.defaultazurecredential?view=azure-python
        
        default_credential = DefaultAzureCredential()

        # If using a User assigned managed identity, you can specify the client id, like this:
        # client_id = "<your client id>"
        # default_credential = DefaultAzureCredential(managed_identity_client_id=client_id)
        # It is also possible to just set environment variable: AZURE_CLIENT_ID

        # Configure the BlobServiceClient
        account_url = f"https://{accountName}.blob.core.windows.net"
        blob_service_client = BlobServiceClient(account_url, credential=default_credential)
        
        # Sample for Uploading a Blob
        upload_blob(blob_service_client,container,sampleUploadBlob)

        # Sample for Listing Blobs
        list_blobs(blob_service_client,container)

        # Sample for Downlaoding a single Blob
        download_blob(blob_service_client,container,sampleDownloadBlob)



