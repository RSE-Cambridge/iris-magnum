terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "openstack" {
  version = "~> 1.25"
}

data "openstack_networking_router_v2" "magnum_router" {
  name = "my-test-53bio6nweivk-network-orueth5zryro-extrouter-wsvsk4jrfljd"
}

data "openstack_networking_network_v2" "magnum_network" {
  network_id = "11df7a40-1801-4b66-b0a6-db8463c58277"
}

data "openstack_networking_network_v2" "internal_network" {
  network_id = "cumulus-internal"
}

resource "openstack_networking_router_v2" "ceph_router" {
  name                = "test-magnum-to-ceph"
  admin_state_up      = true
  enable_snat         = true
  external_network_id = data.openstack_networking_network_v2.internal_network
}


