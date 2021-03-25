variable "host" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "namespace" {
  type    = string
  default = "terraform"
}

variable "registry_name" {
  type = string
}

variable "registry_user" {
  type = string
}

variable "registry_password" {
  type = string
}
