# Deploy a static website as a demo

resource "kubernetes_deployment" "demokub" {
  metadata {
    name      = "demokub-deployment"
    namespace = kubernetes_namespace.terraform.metadata.0.name
    labels = {
      app = "demokub"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "demokub"
      }
    }

    template {
      metadata {
        labels = {
          app = "demokub"
        }
      }

      spec {
        container {
          image = "fabienzucchet/demo-kub:latest"
          name  = "demokub"

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
      }
    }
  }
}

resource "kubernetes_service" "demokub" {
  metadata {
    name      = "demokub-service"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.demokub.metadata.0.labels.app
    }
    port {
      port        = 80
      node_port   = 30123
      target_port = 80
    }

    type = "NodePort"
  }
}
