# Manila CephFS PVC

The example is heavily based on this code:
https://github.com/kubernetes/cloud-provider-openstack/tree/master/examples/manila-provisioner/cephfs

To deploy the demo run, first ensure kubectl can talk to your k8s cluster,
then run:

    ./deploy.sh

And to teardown the demo run:

    ./teardown.sh

## What happens

During the deploy the following steps are completed...

We run a provisioner that is able to talk to OpenStack Manila and create
file shares when requested by kubernetes. This is the manila-provisioner
deployment. The deployment makes use of the service account that is created
in rbac.yml.

Secondly, we create a Storage Class that references appropriate secrets
that are able to talk to the OpenStack Manila APIs. In this example we use
the keystone credentials that were injected by Magnum when it created the
cluster. Note your OpenStack cluster's manila service could have a
different value for CephFS type files, `cephfsnativetype` is just an example
that works on the Cambridge IRIS OpenStack cloud.

Thirdly, we create a persistent volume claim that references the above
Storage Class. Because it is created with the access mode "ReadWriteMany"
you are able to attach it to multiple pods that may be spread across
multiple nodes. When this is created, the manila provisioning uses the
credentials in the referenced StorageClass to create the file share
in manila.

Finally we create a demo app that specifies that the persistent volume should
be mounted under the path /srv. You can attach another workload and see the
files it creates using this demo app.

## Default StorageClass

Its possible to use the storage class we created above as your default
storage class:

    kubectl patch storageclass manila-cephfs-share -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

## Debugging note

Note that the default mode in Manila CephFS is 755. This causes the
above system to only work when you run containers as root. To avoid this
limitation your OpenStack operator needs to set:

    cephfs_volume_mode=777
