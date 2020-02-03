output KUBECONFIG {
   value = module.cluster.kubeconfig
   description = "location of kubectl configuration file"
}

output master_addresses {
   value = module.cluster.master_addresses
   description = "address of the masters"
}
