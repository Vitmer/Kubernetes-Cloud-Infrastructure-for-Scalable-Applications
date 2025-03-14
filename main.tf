resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }
}

resource "helm_release" "postgres" {
  name       = "postgres"
  chart      = "./postgresql-16.5.0.tgz" 
  namespace  = "database"
  create_namespace = true

  set {
    name  = "auth.username"
    value = "admin"
  }

  set {
    name  = "auth.password"
    value = "adminpassword"
  }

  set {
    name  = "auth.database"
    value = "appdb"
  }
}

resource "helm_release" "redis" {
  name       = "redis"
  chart      = "./redis-20.11.3.tgz"
  namespace  = "cache"
  create_namespace = true

  set {
    name  = "auth.password"
    value = "redispassword"
  }

  set {
    name  = "replica.replicaCount"
    value = "1"
  }

  set {
    name  = "master.persistence.enabled"
    value = "true"
  }

  set {
    name  = "master.persistence.size"
    value = "5Gi"
  }
}


 resource "helm_release" "fastapi_app" {
  name       = "fastapi-app"
  chart      = "./charts/fastapi" 
  namespace  = "app"
  create_namespace = true
  
  values = [
    file("./charts/fastapi/values.yaml")
  ]
}