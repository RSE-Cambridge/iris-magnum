output "state" {
  value = openstack_containerinfra_cluster_v1.cluster
}

output "kubeconfig" {
  value = "~/.kube/${var.cluster_name}/config"
}
