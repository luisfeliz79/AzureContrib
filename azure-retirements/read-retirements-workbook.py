############################################################################
#
#                C O D E   S A M P L E
#
#     Azure Advisor Retirements Workbook JSON file reader
#
#     NOTE: The Retirements Workbook file changes often,
#           potentially introducing breaking changes to this script.
#           Please monitor script execution carefully and adjust as needed.
#
#     This code/solution is not officially supported by Microsoft Support
#     
#############################################################################

import requests
import json

def saveFile(filename,data):
    
    with open(filename, 'w',encoding="utf-8") as file:
        file.write(data)
        print (f"Wrote file: {filename}")

# URL of the Azure Advisor Retirements workbook JSON file
url = 'https://raw.githubusercontent.com/microsoft/Application-Insights-Workbooks/refs/heads/master/Workbooks/Azure%20Advisor/AzureServiceRetirement/Azure%20Services%20Retirement.workbook'

# Script variables
masterData='init'
baseQuery='init'

# Download the JSON file
response = requests.get(url)

#Check if the request was successful
if response.status_code == 200:
    #Save the Workbook JSON file to disk
    saveFile("retirements-workbook.json",response.text)

    #Parse the JSON content, extracted needed bits, save to files
    data = response.json()
    for item in data["items"]:
        if (item["name"] == "ParameterDeclaration - BaseQuery"):
            baseQuery = item["content"]["parameters"][0]["value"]
            cleansedBaseQuery = baseQuery.replace("\r\n","").replace("// Query for Classic Redis caches retired","")
            saveFile("retirements-base-kql-query.txt", cleansedBaseQuery)   
            #print(cleansedBaseQuery)

        if (item["name"] == "MasterData"):
            masterData = json.loads(item["content"]["query"])["content"]
            saveFile("retirements-description-data.json",masterData)
            #print(masterData)

else:
   print(f"Failed to download the file. Status code: {response.status_code}")
