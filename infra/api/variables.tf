variable "location" {
  description = "(Optional) The location/region where the resource group will be created"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "(Optional) The name of the resource group"
  type        = string
  default     = ""
}

# variable "imageTag" {
#   description = "The tag of the image to be used"
#   type        = string
#   default     = "latest"
# }

variable "acr_name" {
  description = "(Required) The name of the Azure Container Registry"
  type        = string
  default     = "acrdpWmo"
}

variable "api_name" {
  description = "(Optional) The name of the API"
  type        = string
  default     = "dotnet-podcasts-api"
}

variable "acr_resource_group_name" {
  type = string
  description = "(Optional) The name of the resource group for the Azure Container Registry"
  default = "mrb-dotnet-podcasts-acr"
}

variable "db_login" {
  description = "(Optional) The login for the database"
  type        = string
  default     = "mbraunwart"
}

variable "db_server_name" {
  description = "(Optional) The name of the database server"
  type        = string
  default     = "dotnetpodcasts"

  validation {
    condition     = can(regex("^[0-9a-z]([-0-9a-z]{0,61}[0-9a-z])?$", var.db_server_name))
    error_message = "server name did not match regex \"^[0-9a-z]([-0-9a-z]{0,61}[0-9a-z])?$\""
  }

  validation {
    condition     = length(var.db_server_name) <= 63
    error_message = "server name must be less than or equal to 63 characters"
  }
}

variable "db_name" {
  description = "(Optional) The name of the database"
  type        = string
  default     = "Podcast"
}

variable "image_tag" {
    description = "(Optional) The tag of the image to be used"
    type        = string
    default     = "latest"
}

variable "kubernetes_env_name" {
  description = "(Optional) The name of the Kubernetes environment"
  type        = string
  default     = "sbx"
}

# variable "updater_name" {
#   description = "(Optional) The name of the updater"
#   type        = string
#   default     = ""
# }

# variable "workspace_name" {
#   description = "(Optional) The name of the workspace"
#   type        = string
#   default     = ""
# }
