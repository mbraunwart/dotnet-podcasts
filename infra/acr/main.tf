locals {
  location = var.location == "" ? azurerm_resource_group.rg.location : var.location

  tags = {
    environment = "dev",
    owner       = "mrb",
    project     = "dotnet-podcasts"
  }
}

# data "azurerm_resource_group" "rg" {
#     name = var.resource_group_name
# }

resource "azurerm_resource_group" "rg" {
  name     = "mrb-dotnet-podcasts-acr"
  location = "eastus"
  tags     = local.tags
}

resource "random_id" "r" {
  byte_length = 2
}

resource "azurerm_container_registry" "acr" {
  name                = format("%s%s", var.name, random_id.r.id)
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  sku                 = var.sku
  admin_enabled       = var.admins_user_enabled
  tags = merge({
    type = "acr"
  }, var.tags)
}