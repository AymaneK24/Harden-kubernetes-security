output "cluster_info" {
  value = {
    resource_group_name = azurerm_resource_group.rg.name
    cluster_name        = azurerm_kubernetes_cluster.k8s.name
    host                = azurerm_kubernetes_cluster.k8s.kube_config[0].host
    username            = azurerm_kubernetes_cluster.k8s.kube_config[0].username
  }
  sensitive = false
}




output "cluster_credentials" {
  value = {
    kube_config_raw         = azurerm_kubernetes_cluster.k8s.kube_config_raw
    client_certificate      = azurerm_kubernetes_cluster.k8s.kube_config[0].client_certificate
    client_key              = azurerm_kubernetes_cluster.k8s.kube_config[0].client_key
    cluster_ca_certificate  = azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate
    password                = azurerm_kubernetes_cluster.k8s.kube_config[0].password
  }
  sensitive = true
}