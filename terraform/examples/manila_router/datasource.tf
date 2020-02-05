data "openstack_networking_router_v2" "magnum" {
  name = var.magnum_router_name
}

data "openstack_networking_network_v2" "magnum" {
  network_id = var.magnum_network_id
}

data "openstack_networking_network_v2" "internal_network" {
  name = "cumulus-internal"
}
