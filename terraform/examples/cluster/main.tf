terraform {
  required_version = ">= 0.12, < 0.13"
}

module "cluster" {
  source = "../../modules/cluster"

  cluster_name          = "my-test"
  cluster_template_name = "kubernetes-1.15.9-20200205"
  master_flavor_name    = "general.v1.tiny"
  flavor_name           = "general.v1.tiny"
  master_count          = 1
  node_count            = 1
  max_node_count        = 2
}
