variable "name" {
  type        = string
  description = "(Optional) Name of the azure container registry (must be globally unique)"
  default     = "acrdp"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.name))
    error_message = "Invalid name. Must be alphanumeric characters only."
  }

  validation {
    condition     = length(var.name) >= 5 && length(var.name) <= 50
    error_message = "Invalid name. Must be between 5 and 50 characters."
  }
}

variable "admins_user_enabled" {
  type        = bool
  description = "(Optional) Enable an admin user that has push/pull permission to the registry."
  default     = true
}

# variable "resource_group_name" {
#   type        = string
#   description = "(Required) Name of the resource group in which to create the Azure Container Registry."
# }

variable "location" {
  type        = string
  description = "(Required) Location for all resources."
  default     = "eastus"
}

variable "sku" {
  type        = string
  description = "(Optional) Tier of your Azure Container Registry."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "Invalid SKU. Must be one of Basic, Standard, or Premium."
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources."
  default     = {}
}
