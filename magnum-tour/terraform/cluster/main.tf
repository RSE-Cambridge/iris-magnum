terraform {
  required_version = ">= 0.14"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">=1.39.0"
    }
    null = {
      source = "hashicorp/null"
    }
  }
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
      min_node_count         = var.node_count
      max_node_count         = var.max_node_count
      extra_network          = var.extra_network
  })
}

resource "local_file" "kubeconfig" {
  content         = lookup(openstack_containerinfra_cluster_v1.cluster, "kubeconfig", { raw_config : null }).raw_config
  filename        = pathexpand("~/.kube/${var.cluster_name}/config")
  depends_on      = [openstack_containerinfra_cluster_v1.cluster]
  file_permission = "0600"
}

resource "null_resource" "kubeconfig" {
  triggers = {
    kubeconfig = local_file.kubeconfig.id
  }

  provisioner "local-exec" {
    command = "ln -fs ~/.kube/${var.cluster_name}/config ~/.kube/config"
  }
}
