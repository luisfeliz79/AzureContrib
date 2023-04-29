cd ../../demoapp
mvn clean
mvn package
rm ./tmp/*

cd ..
sudo docker build -t appinsightsdemo .
sudo docker tag appinsightsdemo luisfeliz79/appinsightsdemo
sudo docker push luisfeliz79/appinsightsdemo
cd demoapp
mvn clean

# sudo docker run  -e "AZURE_TENANT_ID=$AZURE_TENANT_ID" -e "AZURE_CLIENT_ID=$AZURE_CLIENT_ID" -e "AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET" -e "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPLICATIONINSIGHTS_CONNECTION_STRING" -e "STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME" appinsightsdemo