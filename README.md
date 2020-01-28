# iris-magnum

Here are some examples of how to use Magnum created
Kubernetes clusters on IRIS Scientific OpenStack Clouds
such as:
https://cumulus.openstack.hpc.cam.ac.uk

This is a digital asset funded by the STFC IRIS cloud:
https://www.iris.ac.uk/

## Getting Started

Firstly, please get access to an IRIS Scientific OpenStack
Cloud. This includes created application credentials so you
are able to access the OpenStack APIs.

For more information, please see:
https://rse-cambridge.github.io/iris-openstack

## Contributing

If you have any problems, please do raise an issue,
or even better, make a pull request that includes a fix
to help others that may hit a similar issue.

## Examples

Generally the later examples build on things used in the
earlier examples.

### Magnum Guided Tour

This example uses terraform to create the k8s cluster,
from a pre-registered Magnum template. For operators,
we provide a link the ansible that registers the given
template.

We give you an overview of what a working Magnum cluster
is able to do out the box. We look at the built in monitoring
and load balancing capabilities.

We also look at using ingress controllers, and kubectl proxy
to limit the number of public IP addresses your cluster will
consume.

### Manila CephFS PVC

We then use kubectl to register a storage class that supports
creating volumes using OpenStack Manila created CephFS shares.

For operators, we discuss the required configuration changes
to fully support this use case.

### Apache Spark with Manila PVC

This uses a helm chart to create an Apache Spark cluster.
It makes use of the above Manila CephFS PVC to provide all
workers with a shared file system that works in a multi-node
cluster.
