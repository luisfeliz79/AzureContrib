
# Authenticate Azure CLI to Azure using the Managed Identity
az login --identity

# Create a SAS token for the Azure Storage Account
# Based on the Managed Identity for the best security
# This method does NOT require the Azure Storage Account Key
# https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-user-delegation-sas-create-cli#create-a-user-delegation-sas-for-a-container

accountName='luisfluentbitsa'
expire_date=$(date -d "+72 hours" +'%Y-%m-%dT%H:%MZ')
permissions='crawl' #(c)reate (r)ead (a)ppend (w)rite (l)ist
fluentbit_sas=$(az storage container generate-sas --permissions $permissions --name "monitoring" --account-name $accountName --expiry $expire_date -o tsv --auth-mode login --as-user)

   # For testing purposes
   # echo $fluentbit_sas


# Construct a directory name based on the Hostname and the date
directory_name="$(hostname)-job-run-$(date +'%Y-%m-%d')"

# Create a Fluent Bit configuration file
# That listens on a TCP socket and writes to Azure Blob Storage
cat <<EOF > fluent-bit.conf

[SERVICE]
    flush     1
    log_level info

[INPUT]
    Name              forward
    Listen            0.0.0.0
    Port              24224

    # Adjust these as per your needs
    Buffer_Chunk_Size 1M
    Buffer_Max_Size   6M

[OUTPUT]
    name                  azure_blob
    match                 *
    account_name          $accountName
    auth_type             sas
    sas_token             $fluentbit_sas
    path                  $directory_name
    container_name        monitoring
    auto_create_container off
    tls                   on

EOF

    # For testing purposes
    # cat fluent-bit.conf

sudo docker stop fluent-bit
sudo docker rm fluent-bit
sudo docker run -v ./fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf \
    --name fluent-bit \
    --net host \
    fluent/fluent-bit /fluent-bit/bin/fluent-bit \
    --config=/fluent-bit/etc/fluent-bit.conf
