module "cluster" {
  source = "./modules/cluster"

  cluster_name           = "example"
  cluster_template_name  = "k8s-1.18.16"
  master_flavor_name     = "general.v1.tiny"
  flavor_name            = "general.v1.tiny"
  master_count           = 1
  node_count             = 2
  max_node_count         = 2
  container_infra_prefix = "harbor.cumulus.openstack.hpc.cam.ac.uk/magnum/"
  extra_network          = "cumulus-internal"
}
