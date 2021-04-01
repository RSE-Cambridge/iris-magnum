module "cluster" {
  source = "./cluster"

  cluster_name          = "magnum-tour"
  cluster_template_name = "kubernetes-1.20.4-20210401"
  master_flavor_name    = "general.v1.tiny"
  flavor_name           = "general.v1.small"
  extra_network         = "cumulus-internal"
  master_count          = 1
  node_count            = 1
  max_node_count        = 2
}
