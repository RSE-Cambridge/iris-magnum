# iris-magnum

Here are some examples of how to use Magnum created
Kubernetes clusters on IRIS Scientific OpenStack Clouds
such as:
https://cumulus.openstack.hpc.cam.ac.uk

This is a digital asset funded by the STFC IRIS cloud:
https://www.iris.ac.uk/

## Contributing

If you have any problems, please do raise an issue,
or even better, make a pull request that includes a fix
to help others that may hit a similar issue.

## Getting Started

Firstly, please get access to an IRIS Scientific OpenStack
Cloud. This includes created application credentials so you
are able to access the OpenStack APIs.

For more information, please see:
https://rse-cambridge.github.io/iris-openstack

To get a good idea of what you can do with Magnum we would recommend trying
out all the demo's in the following sections, in the order listed here.

## OpenStack Magnum Guided Tour

This example uses terraform to create the k8s cluster,
using a pre-registered OpenStack Magnum template.

We give you an overview of what a working Magnum cluster
is able to do out the box. We look at the built in monitoring
and load balancing capabilities.

For more details, see the [Magnum Guided Tour](./magnum-tour/README.md)

## Jupyter Hub (WIP)

For more details see: [Jupyter Hub on Magnum](./jupyterhub/README.md)

## Manila CephFS PVC (WIP)

We then use kubectl to register a storage class that supports
creating volumes using OpenStack Manila created CephFS shares.

For operators, we discuss the required configuration changes
to fully support this use case.

For more details see: [Manila CephFS PVC](./manila-cephfs-pvc/README.md)

## Apache Spark on Magnum (WIP)

This uses a helm chart to create an Apache Spark cluster.
It makes use of the above Manila CephFS PVC to provide all
workers with a shared file system that works in a multi-node
cluster.

For more details see: [Apache Spark on Magnum](./spark/README.md)
