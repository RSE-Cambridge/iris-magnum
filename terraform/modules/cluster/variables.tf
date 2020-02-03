#
# Required Parameters
#

variable "cluster_name" {
  description = "Name of the mangum cluster created"
  type        = string
}

variable "cluster_template_name" {
  description = "Name of the magnum cluster template"
  type        = string
}

variable "flavor_name" {
  description = "Flavor for the worker nodes"
  type = string
}

variable "master_flavor_name" {
  description = "Flavor for the master nodes"
  type = string
}

#
# Optional Parameters
#

variable "public_key_file" {
  type = string
  default = "~/.ssh/id_rsa.pub"
}

variable "master_count" {
  type = number
  default = 1
}

variable "node_count" {
  type = number
  default = 1
}

variable "auto_scaling_enabled" {
  type = string
  default = "true"
}

variable "max_node_count" {
  type = number
  default = 2
}

variable "ingress_controller" {
  type = string
  default = "nginx"
}

variable "monitoring_enabled" {
  type = string
  default = "true"
}

variable "auto_healing_enabled" {
  type = string
  default = "true"
}

variable "master_fip_enabled" {
  type = string
  default = "true"
}

variable "fip_enabled" {
  type = string
  default = "false"
}
