# Azure Firewall Log Viewer

![Screenshot](images/screenshot.png)

## A workbook for analyzing Azure Firewall Network Rules and Application Rules logs
## Requirements:
 - Firewall Logs must be sent to a common Log Analytics workspace
 - Users require minimum of Reader access to Log Analytics workspace
## Installation
### There are different ways to install this workbook

- Using Deploy to Azure

&nbsp;
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fluisfeliz79%2FAzureContrib%2Fmain%2Fazure-firewall-logs-viewer%2FFirewall%2520Logs%2520Viewer%2520ARM%2520Deployment.json)
- Using Terraform

- Via Azure Monitor
  - Go to Azure Monitor > [Workbooks](https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/workbooks)
  - Click on +New
  - Click on the Advanced Editor
  - Copy and paste the contents of workbook.json into the template window, replacing what's already there
  - Click Apply and then Save
