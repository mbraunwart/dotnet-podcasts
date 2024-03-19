output "acr_name" {
    value = azurerm_container_registry.acr.name
    description = "The name of the Azure Container Registry"
}

output "acr_username" {
    value = azurerm_container_registry.acr.admin_username
    description = "The username for the Azure Container Registry"
}

output "acr_password" {
    value = azurerm_container_registry.acr.admin_password
    description = "The password for the Azure Container Registry"
    sensitive = true
}

output "acr_login_server" {
    value = azurerm_container_registry.acr.login_server
    description = "The login server for the Azure Container Registry"
}