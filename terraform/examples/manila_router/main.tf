terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "openstack" {
  version = "~> 1.25"
}

resource "openstack_networking_router_v2" "ceph" {
  name                = "test-magnum-to-ceph"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.internal_network.id
}

resource "openstack_networking_port_v2" "ceph" {
  network_id = data.openstack_networking_network_v2.magnum.id
}

resource "openstack_networking_router_interface_v2" "ceph" {
  router_id = openstack_networking_router_v2.ceph.id
  port_id = openstack_networking_port_v2.ceph.id
}

resource "openstack_networking_router_route_v2" "ceph" {
  depends_on       = ["openstack_networking_router_interface_v2.ceph"]
  router_id        = data.openstack_networking_router_v2.magnum.id
  destination_cidr = "10.206.0.0/16"
  next_hop         = openstack_networking_port_v2.ceph.all_fixed_ips[0]
}
