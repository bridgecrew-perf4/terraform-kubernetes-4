terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  host = var.host

  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

resource "kubernetes_namespace" "terraform" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "docker_pull_secret" {
  metadata {
    name      = "registry-vr"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }

  data = {
    ".dockercfg" = <<DOCKER
  {
    "${var.registry_name}": {
        "username": "${var.registry_user}",
        "password": "${var.registry_password}"
    }
}
DOCKER
  }

  type = "kubernetes.io/dockercfg"
}

