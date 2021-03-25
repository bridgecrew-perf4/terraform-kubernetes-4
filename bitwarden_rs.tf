# Deploy bitwarden_rs
variable "smtp_host" {
  type = string

}

variable "smtp_from" {
  type = string
}

variable "smtp_port" {
  type = number
}

variable "domain" {
  type = string
}


resource "kubernetes_deployment" "bitwarden_rs" {
  metadata {
    name      = "bitwarden-rs-deployment"
    namespace = kubernetes_namespace.terraform.metadata.0.name
    labels = {
      app = "bitwarden"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "bitwarden"
      }
    }

    template {
      metadata {
        labels = {
          app = "bitwarden"
        }
      }

      spec {

        volume {
          name = "bitwarden-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.bitwarden_rs.metadata[0].name
          }
        }

        container {
          image = "bitwardenrs/server"
          name  = "bitwarden-rs"

          port {
            container_port = 80
          }

          volume_mount {
            mount_path = "/data"
            name       = "bitwarden-storage"
          }

          env {
            name  = "SMTP_HOST"
            value = var.smtp_host
          }

          env {
            name  = "SMTP_FROM"
            value = var.smtp_from
          }

          env {
            name  = "SMTP_PORT"
            value = var.smtp_port
          }

          env {
            name  = "SMTP_SSL"
            value = "true"
          }

          env {
            name  = "SMTP_ACCEPT_INVALID_CERTS"
            value = "true"
          }

          env {
            name  = "DOMAIN"
            value = var.domain
          }

        }
      }
    }
  }
}


resource "kubernetes_service" "bitwarden_rs" {
  metadata {
    name      = "bitwarden-rs-service"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.bitwarden_rs.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 80
      node_port   = 30128
    }

    type = "NodePort"
  }
}

resource "kubernetes_persistent_volume" "bitwarden_rs" {
  metadata {
    name = "bitwarden-rs-pv"
  }
  spec {
    capacity = {
      storage = "5Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Delete"
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["coshyperbolix.cs-campus.fr"]
          }
        }
      }
    }
    persistent_volume_source {
      local {
        path = "/mnt"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "bitwarden_rs" {
  metadata {
    name      = "bitwarden-rs-pvc"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.bitwarden_rs.metadata.0.name
  }
}
