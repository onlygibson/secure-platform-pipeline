terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-spp"
}

# App namespace: "restricted" blocks root and privileged pods
resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = "spp-app"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "owner"                              = "platform"
    }
  }
}

# App settings: debug off in this environment
resource "kubernetes_config_map_v1" "app_settings" {
  metadata {
    name      = "app-settings"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  data = {
    LOG_LEVEL = "info"
    DEBUG     = "false"
  }
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-spp"
  }
}
