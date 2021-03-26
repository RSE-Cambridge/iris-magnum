module "cluster" {
  source = "./cluster"

  cluster_name          = "magnum-tour"
  cluster_template_name = "k8s-1.20.4"
  master_flavor_name    = "general.v1.tiny"
  flavor_name           = "general.v1.tiny"
  master_count          = 1
  node_count            = 1
  max_node_count        = 2
}
