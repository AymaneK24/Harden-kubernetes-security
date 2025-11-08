terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "projet_intégré"
    storage_account_name = "myterraformbackendsa"
    container_name       = "tfstate"
    key                  = "infrastructure.terraform.tfstate"
  }
}
