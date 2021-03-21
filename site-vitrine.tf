# Deploy a static website as a demo

resource "kubernetes_deployment" "site-vitrine" {
  metadata {
    name      = "site-vitrine-deployment"
    namespace = kubernetes_namespace.terraform.metadata.0.name
    labels = {
      app = "site-vitrine"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "site-vitrine"
      }
    }

    template {
      metadata {
        labels = {
          app = "site-vitrine"
        }
      }

      spec {
        container {
          image = "registry.viarezo.fr/cosx/site-vitrine:latest"
          name  = "site-vitrine"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
        image_pull_secrets {
          name = kubernetes_secret.docker_pull_secret.metadata.0.name
        }
      }
    }
  }
}

resource "kubernetes_service" "site-vitrine" {
  metadata {
    name      = "site-vitrine-service"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.site-vitrine.metadata.0.labels.app
    }
    port {
      port        = 80
      node_port   = 30125
      target_port = 80
    }

    type = "NodePort"
  }
}
