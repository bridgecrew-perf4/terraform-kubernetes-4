# Deploy a leaderboard

resource "kubernetes_deployment" "leaderboard_mysql" {
  metadata {
    name      = "leaderboard-mysql-deployment"
    namespace = kubernetes_namespace.terraform.metadata.0.name
    labels = {
      app  = "leaderboard"
      tier = "mysql"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "leaderboard"
        tier = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app  = "leaderboard"
          tier = "mysql"
        }
      }

      spec {

        volume {
          name = "leaderboard-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.leaderboard_mysql.metadata[0].name
          }
        }

        container {
          image = "mysql:5.7"
          name  = "leaderboard-mysql"

          port {
            container_port = 3306
          }

          volume_mount {
            mount_path = "/var/lib/mysql"
            name       = "leaderboard-storage"
            sub_path   = "leaderboard-mysql"
          }

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = var.db_root_user
          }
          env {
            name  = "MYSQL_DATABASE"
            value = var.db_name
          }
          env {
            name  = "MYSQL_USER"
            value = var.db_user
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = var.db_password
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "leaderboard_mysql" {
  metadata {
    name      = "leaderboard-mysql-service"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    selector = {
      app  = kubernetes_deployment.leaderboard_mysql.metadata.0.labels.app
      tier = kubernetes_deployment.leaderboard_mysql.metadata.0.labels.tier
    }
    port {
      port = 3306
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_persistent_volume" "leaderboard_mysql" {
  metadata {
    name = "leaderboard-mysql-pv"
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

resource "kubernetes_persistent_volume_claim" "leaderboard_mysql" {
  metadata {
    name      = "leaderboard-mysql-pvc"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.leaderboard_mysql.metadata.0.name
  }
}

##### FRONT #####

resource "kubernetes_deployment" "leaderboard_front" {
  metadata {
    name      = "leaderboard-front-deployment"
    namespace = kubernetes_namespace.terraform.metadata.0.name
    labels = {
      app  = "leaderboard"
      tier = "front"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "leaderboard"
        tier = "front"
      }
    }

    template {
      metadata {
        labels = {
          app  = "leaderboard"
          tier = "front"
        }
      }

      spec {

        container {
          image = "registry.viarezo.fr/cosx/leaderboard-front"
          name  = "leaderboard-front"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "leaderboard_front" {
  metadata {
    name      = "leaderboard-front-service"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    selector = {
      app  = kubernetes_deployment.leaderboard_front.metadata.0.labels.app
      tier = kubernetes_deployment.leaderboard_front.metadata.0.labels.tier
    }
    port {
      port        = 80
      node_port   = 30130
      target_port = 80
    }

    type = "NodePort"
  }
}
