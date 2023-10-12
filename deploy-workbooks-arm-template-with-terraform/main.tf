terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.71.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features{}
}

resource "azurerm_resource_group" "workbook" {
  name     = "testworkbook"
  location = "eastus"
}

resource "azurerm_resource_group_template_deployment" "deployWorkbook" {
  name                = "deploy-workbook2"
  resource_group_name = "testworkbook"
  deployment_mode     = "Incremental"
  
  template_content   = file("${path.module}/sample.json")

  parameters_content = jsonencode(jsondecode(file("${path.module}/sample.params.json")).parameters)

}

