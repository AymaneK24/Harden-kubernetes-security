variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}


variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "integrated_project_resource_group"
}


variable "resource_group_location" {
  description = "Location of the resource group"
  type        = string
  default     = "eastus"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "integrated_project_aks_cluster"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for AKS cluster"
  type        = string
  default     = "integrated_project_aks_cluster"
}

variable "node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 1
}

variable "username" {
  description = "Admin username for the cluster"
  type        = string
  default     = "azureuser"
}

