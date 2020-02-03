terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "openstack" {
  version = "~> 1.25"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = var.cluster_name
  public_key = file(var.public_key_file)
}

resource "openstack_containerinfra_cluster_v1" "cluster" {
  name                 = var.cluster_name
  cluster_template_id  = data.openstack_containerinfra_clustertemplate_v1.clustertemplate.id

  master_count         = var.master_count
  node_count           = var.node_count

  keypair              = openstack_compute_keypair_v2.keypair.id
  flavor               = var.flavor_name
  master_flavor        = var.master_flavor_name

  labels = {
    fip_enabled                        = var.fip_enabled
    master_lb_floating_ip_enabled       = var.master_fip_enabled
    ingress_controller                  = var.ingress_controller

    monitoring_enabled                  = var.monitoring_enabled

    auto_scaling_enabled                = var.auto_scaling_enabled
    min_node_count                      = var.node_count
    max_node_count                      = var.max_node_count
    auto_healing_enabled                = var.auto_healing_enabled
  }

  provisioner "local-exec" {
    command = "mkdir -p ~/.kube/magnum; openstack coe cluster config ${var.cluster_name} --dir ~/.kube/magnum --force"
  }
}
