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

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  create_namespace = true

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "defaultBackend.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
}

resource "helm_release" "postgres" {
  name       = "postgres"
  chart      = "./postgresql-16.5.0.tgz"  # Указываем скачанный локальный файл
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
  chart      = "./charts/fastapi"  # Указываем путь к локальному Helm-чарту (его нужно создать)
  namespace  = "app"
  create_namespace = true

  set {
    name  = "image.repository"
    value = "vitmer/mlopsclassification-model"
  }

  set {
    name  = "image.tag"
    value = "latest"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "service.port"
    value = "8000"
  }

  set {
    name  = "postgresql.host"
    value = "postgres-postgresql"
  }

  set {
    name  = "postgresql.username"
    value = "admin"
  }

  set {
    name  = "postgresql.password"
    value = "adminpassword"
  }

  set {
    name  = "redis.host"
    value = "redis-master"
  }

  set {
    name  = "redis.password"
    value = "redispassword"
  }

  values = [
    file("./charts/fastapi/values.yaml")
  ]
}

resource "helm_release" "fastapi_ingress" {
  name       = "fastapi-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "app"
  create_namespace = true

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }

  set {
    name  = "controller.ingressClassResource.skip-crds"
    value = "true"
  }
}

resource "kubernetes_config_map" "example_config" {
  metadata {
    name      = "example-config"
    namespace = "app"
  }

  data = {
    "DATABASE_URL" = "postgresql://admin:adminpassword@postgres-postgresql:5432/appdb"
    "REDIS_URL"    = "redis-master:6379"
  }
}

resource "kubernetes_secret" "example_secret" {
  metadata {
    name      = "example-secret"
    namespace = "app"
  }

  data = {
    "REDIS_PASSWORD" = base64encode("redispassword")
    "POSTGRES_PASSWORD" = base64encode("adminpassword")
  }
}