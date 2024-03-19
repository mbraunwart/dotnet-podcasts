locals {
  podcast_db_connection_string = format("Server=tcp:%s%s,1433;Initial Catalog=%s;Persist Security Info=False;User ID=%s;Password=%s;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;", azurerm_mssql_server.sql_server.name, azurerm_mssql_server.sql_server.fully_qualified_domain_name, azurerm_mssql_database.sql_db.name, var.db_login, random_password.p.result)
}

data "azurerm_client_config" "current" {

}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

resource "random_id" "r" {
  byte_length = 2
}

resource "random_password" "p" {
  length      = 16
  min_numeric = 2
  min_lower   = 2
  min_special = 2
  min_upper   = 2
}

resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = "mrb-dotnet-podcasts-sbx"

}

resource "azurerm_key_vault" "kv" {
  name                            = format("dotnet-podcasts-%s", random_id.r.hex)
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  soft_delete_retention_days      = 7

  access_policy = [{
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = data.azurerm_client_config.current.object_id
    application_id          = data.azurerm_client_config.current.client_id
    key_permissions         = ["Create", "Delete", "Get", "List", "Update", "Import", "Backup", "Restore", "Recover", "Purge"]
    secret_permissions      = ["Delete", "Get", "List", "Set", "Purge", "Recover", "Restore"]
    certificate_permissions = []
    storage_permissions     = []
  }]
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = var.db_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_login
  administrator_login_password = random_password.p.result
}

resource "azurerm_mssql_database" "sql_db" {
  name      = var.db_name
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "Basic"
}

resource "azurerm_mssql_firewall_rule" "fw" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_storage_account" "sa" {
  name                     = format("dotnetpodcasts%s", random_id.r.hex)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"
}

resource "azurerm_storage_queue" "saq" {
  name                 = "feed-queue"
  storage_account_name = azurerm_storage_account.sa.name
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = format("dotnetpodcasts%s", random_id.r.hex)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = var.api_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_container_app" "api" {
  name                         = var.api_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"
  registry {
    server               = data.azurerm_container_registry.acr.login_server
    username             = data.azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }
  secret {
    name  = "feedqueue"
    value = format("DefaultEndpointProtocol=https;AccountName=%s;EndpointSuffix=core.windows.net;AccountKey=%s", azurerm_storage_account.sa.name, azurerm_storage_account.sa.primary_access_key)
  }
  secret {
    name  = "podcastdb"
    value = local.podcast_db_connection_string
  }
  secret {
    name  = "acr-password"
    value = data.azurerm_container_registry.acr.admin_password
  }
  template {
    min_replicas = 1
    max_replicas = 5

    container {
      image  = format("%s/podcastapi:%s", data.azurerm_container_registry.acr.login_server, var.image_tag)
      name   = "podcastapi"
      cpu    = 1
      memory = "2Gi"
      env {
        name        = "ConnectionStrings__FeedQueue"
        secret_name = "feedqueue"
      }
      env {
        name        = "ConnectionStrings__PodcastDb"
        secret_name = "podcastdb"
      }
      env {
        name  = "Features__FeedIngestion"
        value = false
      }
    }
    http_scale_rule {
      name                = "httpscalingrule"
      concurrent_requests = 20
    }
  }
}

resource "azurerm_container_app" "ingestion" {
  name                         = "podcastingestionca"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"
  registry {
    server               = data.azurerm_container_registry.acr.login_server
    username             = data.azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }
  secret {
    name  = "feedqueue"
    value = format("DefaultEndpointProtocol=https;AccountName=%s;EndpointSuffix=core.windows.net;AccountKey=%s", azurerm_storage_account.sa.name, azurerm_storage_account.sa.primary_access_key)
  }
  secret {
    name  = "podcastdb"
    value = local.podcast_db_connection_string
  }
  secret {
    name  = "acr-password"
    value = data.azurerm_container_registry.acr.admin_password
  }
  template {
    min_replicas = 0
    max_replicas = 5

    container {
      image  = format("%s/podcastingestion:%s", data.azurerm_container_registry.acr.login_server, var.image_tag)
      name   = "podcastingestion"
      cpu    = 1
      memory = "2Gi"
      env {
        name        = "ConnectionStrings__FeedQueue"
        secret_name = "feedqueue"
      }
      env {
        name        = "ConnectionStrings__PodcastDb"
        secret_name = "podcastdb"
      }
    }
    custom_scale_rule {
      name             = "queue-scaling-rule"
      custom_rule_type = "azure-queue"
      metadata = {
        "queueName"   = "feed-queue"
        "queueLength" = 20
      }
      authentication {
        secret_name       = "feedqueue"
        trigger_parameter = "connection"
      }
    }
  }
}

resource "azurerm_container_app" "updater" {
  name                         = "podcastupdaterca"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"
  registry {
    server               = data.azurerm_container_registry.acr.login_server
    username             = data.azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }
  secret {
    name  = "podcastdb"
    value = local.podcast_db_connection_string
  }
  secret {
    name  = "acr-password"
    value = data.azurerm_container_registry.acr.admin_password
  }
  template {
    min_replicas = 0
    max_replicas = 1

    container {
      image  = format("%s/podcastupdater:%s", data.azurerm_container_registry.acr.login_server, var.image_tag)
      name   = "podcastupdater"
      cpu    = 1
      memory = "2Gi"
      env {
        name        = "ConnectionStrings__FeedQueue"
        secret_name = "feedqueue"
      }
      env {
        name  = "Storage__Images"
        value = format("%s/covers/", azurerm_storage_account.sa.primary_blob_host)
      }
    }
    custom_scale_rule {
      name             = "queue-scaling-rule"
      custom_rule_type = "azure-queue"
      metadata = {
        "queueName"   = "feed-queue"
        "queueLength" = 20
      }
      authentication {
        secret_name       = "feedqueue"
        trigger_parameter = "connection"
      }
    }
  }
}

locals {
  key_vault_secrets = [
    {
      name  = "PodcastDBConnectionString"
      value = local.podcast_db_connection_string
    },
    {
      name  = "PodcastDBUserName"
      value = var.db_login
    },
    {
      name  = "PodcastDBPassword"
      value = random_password.p.result
    },
    {
      name  = "PodcastDBServer"
      value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
    },
    {
      name  = "PodcastDBName"
      value = azurerm_mssql_database.sql_db.name
    },
    {
      name  = "StorageAccountName"
      value = azurerm_storage_account.sa.name
    },
    {
      name  = "StorageAccountKey"
      value = azurerm_storage_account.sa.primary_access_key
    },
    {
      name  = "FeedQueueConnectionString"
      value = format("DefaultEndpointProtocol=https;AccountName=%s;EndpointSuffix=core.windows.net;AccountKey=%s", azurerm_storage_account.sa.name, azurerm_storage_account.sa.primary_access_key)
    },
    {
      name  = "StorageAccountQueue"
      value = azurerm_storage_queue.saq.name
    },
    {
      name  = "LogAnalyticsWorkspaceId"
      value = azurerm_log_analytics_workspace.law.id
    },
    {
      name  = "LogAnalyticsWorkspaceKey"
      value = azurerm_log_analytics_workspace.law.primary_shared_key
    },
    {
      name  = "APIName"
      value = azurerm_container_app.api.name
    },
    {
      name  = "IngestionName"
      value = azurerm_container_app.ingestion.name
    },
    {
      name  = "UpdaterName"
      value = azurerm_container_app.updater.name
    }
  ]
}

resource "azurerm_key_vault_secret" "s" {
  for_each     = { for s in local.key_vault_secrets : s.name => s }
  key_vault_id = azurerm_key_vault.kv.id
  name         = each.key
  value        = each.value.value
}
