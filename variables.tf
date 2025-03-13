variable "resource_group_name" {
  description = "Имя группы ресурсов"
  type        = string
  default     = "rg-k8s-infra"
}

variable "location" {
  description = "Регион Azure"
  type        = string
  default     = "West Europe"
}

variable "aks_cluster_name" {
  description = "Имя AKS-кластера"
  type        = string
  default     = "aks-cluster"
}

variable "node_count" {
  description = "Количество узлов в кластере"
  type        = number
  default     = 3
}