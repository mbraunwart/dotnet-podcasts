terraform {
    required_version = "<= 1.7.5"
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "<= 3.95.0"
        }
    }

    cloud {
        organization = "insight"
        workspaces {
            name = "mrb-aks-api-dev"
        }
    }
}

provider "azurerm" {
    features {}
}