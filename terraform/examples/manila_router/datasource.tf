data "openstack_networking_router_v2" "magnum" {
  name = "my-test-53bio6nweivk-network-orueth5zryro-extrouter-wsvsk4jrfljd"
}

data "openstack_networking_network_v2" "magnum" {
  network_id = "11df7a40-1801-4b66-b0a6-db8463c58277"
}

data "openstack_networking_network_v2" "internal_network" {
  name = "cumulus-internal"
}
