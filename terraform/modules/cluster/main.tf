terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "openstack" {
  version = ">= 1.29"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = var.cluster_name
  public_key = file(var.public_key_file)
}

resource "openstack_containerinfra_cluster_v1" "cluster" {
  name                = var.cluster_name
  cluster_template_id = data.openstack_containerinfra_clustertemplate_v1.clustertemplate.id

  master_count = var.master_count
  node_count   = var.node_count

  keypair       = openstack_compute_keypair_v2.keypair.id
  flavor        = var.flavor_name
  master_flavor = var.master_flavor_name

  labels = merge(data.openstack_containerinfra_clustertemplate_v1.clustertemplate.labels,
    {
      min_node_count = var.node_count
      max_node_count = var.max_node_count
  })
}

resource "null_resource" "kubeconfig" {
  triggers = {
    kubeconfig = var.cluster_name
  }

  provisioner "local-exec" {
    command = "mkdir -p ~/.kube/${var.cluster_name}; openstack coe cluster config ${var.cluster_name} --dir ~/.kube/${var.cluster_name} --force;"
  }

  depends_on = [openstack_containerinfra_cluster_v1.cluster]
}
