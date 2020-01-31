# Manila CephFS PVC

The example is heavily based on this code:
https://github.com/kubernetes/cloud-provider-openstack/tree/master/examples/manila-provisioner/cephfs

We run a provisioner that is able to talk to OpenStack Manila and create
file shares when requested by kubernetes. This is the manila-provisioner
deployment. The deployment makes use of the service account that is created
in rbac.yml.

Secondly, we create a Storage Class that references appropriate secrets
that are able to talk to the OpenStack Manila APIs.

Thirdly, we create a persistent volume claim that references the above
Storage Class. Because it is created with the access mode "ReadWriteMany"
you are able to attach it to multiple pods that may be spread across
multiple nodes. When this is created, the manila provisioning uses the
credentials in the referenced StorageClass to create the file share
in manila.

Finally we create a demo app that specifies that the persistent volume should
be mounted under the path /srv. You can attach another workload and see the
files it creates using this demo app.
