variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "integrated-project-rg"
}

variable "resource_group_location" {
  description = "Location of the resource group"
  type        = string
  default     = "eastus"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "integrated-project-aks"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for AKS cluster"
  type        = string
  default     = "integrated-project"
}

variable "node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 1
}