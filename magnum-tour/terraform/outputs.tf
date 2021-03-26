output "api_address" {
  value       = module.cluster.state.api_address
  description = "cluster api address"
}

output "export" {
  value       = "KUBECONFIG=${module.cluster.kubeconfig}"
  description = "snippet to update location of kubectl configuration file"
}
