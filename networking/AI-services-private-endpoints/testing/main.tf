locals {
  service_array = [
    {
      kind = "AnomalyDetector"
      sku  = "S0"      
    },
    {
      kind = "CognitiveServices"
      sku  = "S0"
    },
    {
      kind = "ContentModerator"
      sku  = "S0"
    },
    {
      kind = "ContentSafety"
      sku  = "S0"
    },
    {
      kind = "CustomVision.Prediction"
      sku  = "S0"
    },
    {
      kind = "CustomVision.Training"
      sku  = "S0"
    },
    {
      kind = "Face"
      sku  = "S0"
    },
    {
      kind = "FormRecognizer"
      sku  = "S0"
    },
    {
      kind = "ImmersiveReader"
      sku  = "S0"
    },
    {
      kind = "OpenAI"
      sku  = "S0"
    },
    {
      kind = "SpeechServices"
      sku  = "S0"
    },
    {
      kind = "ComputerVision"
      sku  = "S1"
    },
    {
      kind = "TextAnalytics"
      sku  = "S"
    },
    {
      kind = "TextTranslation"
      sku  = "S1"
    }
  ]

}

resource "azurerm_resource_group" "rg" {
  name     = "cognitive-services-automated-tests-rg"
  location = local.region
}

// create cognitive services accounts
resource "azurerm_cognitive_account" "service" {

  for_each = { for idx, val in local.service_array : idx => val }

  name                = "${local.prefix}-${lower(replace(each.value.kind, ".", "_"))}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = each.value.kind

  custom_subdomain_name = "${local.prefix}-${lower(replace(each.value.kind, ".", ""))}"

  sku_name = each.value.sku

  tags = {
    Acceptance = "Test"
  }
}

// Create an AI Services
resource "azurerm_ai_services" "aiservice" {

  name                = "${local.prefix}-ai-service"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "S0"

  custom_subdomain_name = "${local.prefix}aisvc"

  tags = {
    Acceptance = "Test"
  }
}


// create a vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "cognitive-services-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    Acceptance = "Test"
  }
}

// create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "endpoints-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

// create a private endpoint for each cognitive service
resource "azurerm_private_endpoint" "private_endpoint" {
    for_each = azurerm_cognitive_account.service

    name                = "${each.value.name}-pe"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    subnet_id           = azurerm_subnet.subnet.id

    private_service_connection {
        name                           = "${each.value.name}-peconnection"
        is_manual_connection           = false
        private_connection_resource_id = each.value.id
        subresource_names              = ["account"]
    }

    lifecycle {
      ignore_changes = [ private_dns_zone_group ]
    }
}

// create a private endpoint for AI services
resource "azurerm_private_endpoint" "private_endpoint_ai_service" {

    name                = "${azurerm_ai_services.aiservice.name}-pe"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    subnet_id           = azurerm_subnet.subnet.id

    private_service_connection {
        name                           = "${azurerm_ai_services.aiservice.name}-peconnection"
        is_manual_connection           = false
        private_connection_resource_id = azurerm_ai_services.aiservice.id
        subresource_names              = ["account"]
    }

    lifecycle {
      ignore_changes = [ private_dns_zone_group ]
    }
}

