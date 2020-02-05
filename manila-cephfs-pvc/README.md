# Manila CephFS PVC

Here we talk about how to provide storage that can be attached for write
by multiple pods across multiple servers, backed by OpenStack Manila's
CephFS support.

This contrasts with using Cinder volumes, where you have a RBD block device
attached to a VM and bind mounted into a VM. Typically you cannot mount the
filesystem on such a block device on multiple servers, without risking data
corruption.

## Networking to CephFS

We need an extra router for the private network that is created by Magnum to
reach the 10.206.0.0/16 network on which the CephFS storage is exposed.
This is done by adding a router with its gateway onto the 10.218.0.0/16
network, and adding a static route of the default router for the Magnum
cluster.

An example of how to automate the creation of this router with terraform
can be found here:
https://github.com/RSE-Cambridge/iris-magnum/tree/master/terraform/examples/manila_router

You can generate the required values like this:

    cd terrafrom/examples/manila_router
    
    cluster_name=my-cluster
    
    subnet_name=`openstack subnet list -c Name -f value | grep ${cluster_name}-`
    network_id=`openstack subnet list --name $subnet_name -c Network -f value`
    router_name=`openstack router list -c Name -f value | grep ${cluster_name}-`
    
    cat >terraform.tfvars <<END
    magnum_network_id = "$network_id"
    magnum_router_name = "$router_name"
    END

Now you can apply the above terrafrom example:

    terraform apply

## Connect K8s to OpenStack Manila

The example is heavily based on this code:
https://github.com/kubernetes/cloud-provider-openstack/tree/master/examples/manila-provisioner/cephfs

To deploy the demo run, first ensure kubectl can talk to your k8s cluster,
then run:

    cd manila-cephfs-pvc
    
    ./deploy.sh

To access the demo file browser web app on http://localhost:8000 run the following
and login with username:admin password:admin

    kubectl port-forward svc/demo-svc 8000:80

And to teardown the demo run:

    ./teardown.sh

### What happens

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

### Default StorageClass

Its possible to use the storage class we created above as your default
storage class:

    kubectl patch storageclass manila-cephfs-share -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

Note: you may have already made cinder your default storage drive if you have
followed earlier parts of this tutorial.

### Debugging note

Note that the default mode in Manila CephFS is 755. This causes the
above system to only work when you run containers as root. To avoid this
limitation your OpenStack operator needs to set:

    cephfs_volume_mode=777
