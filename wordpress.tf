# Deploy a Wordpress website

variable "db_root_user" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_name" {
  type = string
}

resource "kubernetes_deployment" "wordpress_mysql" {
  metadata {
    name      = "wordpress-mysql-deployment"
    namespace = kubernetes_namespace.terraform.metadata.0.name
    labels = {
      app  = "wordpress"
      tier = "mysql"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "wordpress"
        tier = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app  = "wordpress"
          tier = "mysql"
        }
      }

      spec {

        volume {
          name = "wordpress-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wordpress_mysql.metadata[0].name
          }
        }

        container {
          image = "mysql:5.7"
          name  = "wordpress-mysql"

          port {
            container_port = 3306
          }

          volume_mount {
            mount_path = "/var/lib/mysql"
            name       = "wordpress-storage"
            sub_path   = "mysql"
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

resource "kubernetes_service" "wordpress_mysql" {
  metadata {
    name      = "wordpress-mysql-service"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    selector = {
      app  = kubernetes_deployment.wordpress_mysql.metadata.0.labels.app
      tier = kubernetes_deployment.wordpress_mysql.metadata.0.labels.tier
    }
    port {
      port = 3306
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_persistent_volume" "wordpress_mysql" {
  metadata {
    name = "wordpress-mysql-pv"
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

resource "kubernetes_persistent_volume_claim" "wordpress_mysql" {
  metadata {
    name      = "wordpress-mysql-pvc"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.wordpress_mysql.metadata.0.name
  }
}


######### WORDPRESS ##########

resource "kubernetes_deployment" "wordpress_front" {
  metadata {
    name      = "wordpress-front-deployment"
    namespace = kubernetes_namespace.terraform.metadata.0.name
    labels = {
      app  = "wordpress"
      tier = "front"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "wordpress"
        tier = "front"
      }
    }

    template {
      metadata {
        labels = {
          app  = "wordpress"
          tier = "front"
        }
      }

      spec {

        volume {
          name = "wordpress-front-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wordpress_front.metadata[0].name
          }
        }

        container {
          image = "wordpress"
          name  = "wordpress-front"

          port {
            container_port = 80
          }

          volume_mount {
            mount_path = "/var/www/html"
            name       = "wordpress-front-storage"
          }

          env {
            name  = "WORDPRESS_DB_HOST"
            value = kubernetes_service.wordpress_mysql.metadata.0.name
          }
          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = var.db_password
          }
          env {
            name  = "WORDPRESS_DB_USER"
            value = var.db_user
          }
          env {
            name  = "WORDPRESS_DB_NAME"
            value = var.db_name
          }
          env {
            name  = "WORDPRESS_CONFIG_EXTRA"
            value = "if ( (!empty( $_SERVER['HTTP_X_FORWARDED_HOST'])) ||      (!empty( $_SERVER['HTTP_X_FORWARDED_FOR'])) ) {     $_SERVER['HTTPS'] = 'on'; }"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress_front" {
  metadata {
    name      = "wordpress-front-service"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    selector = {
      app  = kubernetes_deployment.wordpress_front.metadata.0.labels.app
      tier = kubernetes_deployment.wordpress_front.metadata.0.labels.tier
    }
    port {
      port        = 80
      node_port   = 30127
      target_port = 80
    }

    type = "NodePort"
  }
}

resource "kubernetes_persistent_volume" "wordpress_front" {
  metadata {
    name = "wordpress-front-pv"
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

resource "kubernetes_persistent_volume_claim" "wordpress_front" {
  metadata {
    name      = "wordpress-front-pvc"
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.wordpress_front.metadata.0.name
  }
}
