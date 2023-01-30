# Azure Firewall Log Viewer

![Screenshot](images/screenshot.png)

## An Azure Workbook for analyzing Azure Firewall Network Rules and Application Rules logs
## Requirements:
 - Firewall Logs must be sent to a common Log Analytics workspace
 - Users require minimum RBAC of Reader permissions to Log Analytics workspace

&nbsp;
## Installation
### There are multiple ways to install this Azure Workbook

- Using this installation button:
&nbsp;
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fluisfeliz79%2FAzureContrib%2Fmain%2Fazure-firewall-logs-viewer%2FFirewall%2520Logs%2520Viewer%2520ARM%2520Deployment.json)


&nbsp;
- Using an ARM Template
[Firewall Logs Viewer ARM Deployment.json](https://github.com/luisfeliz79/AzureContrib/blob/main/azure-firewall-logs-viewer/Firewall%20Logs%20Viewer%20ARM%20Deployment.json)


&nbsp;
- Manually via Azure Monitor
  - Go to Azure Monitor > [Workbooks](https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/workbooks)
  - Click on +New
  - Click on the Advanced Editor
  - Copy and paste the contents of [Firewall Logs viewer.workbook](https://raw.githubusercontent.com/luisfeliz79/AzureContrib/main/azure-firewall-logs-viewer/Firewall%20Logs%20viewer.workbook) into the template window, replacing what's already there
  - Click Apply and then Save

&nbsp;
## Configuring Defaults
### Once the Workbook has been installed, click edit and...
- Choose the **Workspace** that contains firewall logs
- Configure the default **Time range**
- Optionally select
	- Firewall selections
	- Rule type and Action

- Click Save

