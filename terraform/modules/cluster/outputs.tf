output master_addresses {
  value = openstack_containerinfra_cluster_v1.cluster.master_addresses
}

output kubeconfig {
  value = "~/.kube/${var.cluster_name}/config"
}
