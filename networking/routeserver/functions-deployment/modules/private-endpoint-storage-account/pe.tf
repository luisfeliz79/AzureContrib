data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.zone_rg
}
data "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.zone_rg
}
data "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.zone_rg
}
data "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = var.zone_rg
}




# Private Endpoints setup
resource "azurerm_private_endpoint" "peblob" {
  name                = "pe-blob-${var.sa_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoints_subnet_id

  private_service_connection {
    name                           = "pe-connection-blob-${var.sa_name}"
    private_connection_resource_id = var.sa_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  private_dns_zone_group {
    name                 = data.azurerm_private_dns_zone.blob.name
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  }

  lifecycle {
    ignore_changes = all
  }

}

resource "azurerm_private_endpoint" "pefile" {
  name                = "pe-file-${var.sa_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoints_subnet_id
  private_service_connection {
    name                           = "pe-connection-file-${var.sa_name}"
    private_connection_resource_id = var.sa_id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
  private_dns_zone_group {
    name                 = data.azurerm_private_dns_zone.file.name
    private_dns_zone_ids = [data.azurerm_private_dns_zone.file.id]
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_private_endpoint" "petable" {
  name                = "pe-table-${var.sa_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoints_subnet_id
  private_service_connection {
    name                           = "pe-connection-table-${var.sa_name}"
    private_connection_resource_id = var.sa_id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }
  private_dns_zone_group {
    name                 = data.azurerm_private_dns_zone.table.name
    private_dns_zone_ids = [data.azurerm_private_dns_zone.table.id]
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_private_endpoint" "pequeue" {
  name                = "pe-queue-${var.sa_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoints_subnet_id
  private_service_connection {
    name                           = "pe-connection-queue-${var.sa_name}"
    private_connection_resource_id = var.sa_id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }
  private_dns_zone_group {
    name                 = data.azurerm_private_dns_zone.queue.name
    private_dns_zone_ids = [data.azurerm_private_dns_zone.queue.id]
  }
  lifecycle {
    ignore_changes = all
  }
}