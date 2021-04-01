Manila CSI
==========

Here we talk about how to provide storage that can be attached for write by multiple pods across multiple servers, backed by OpenStack Manila's CephFS support.

This contrasts with using Cinder volumes, where you have a RBD block device attached to a VM and bind mounted into a VM. Typically you cannot mount the filesystem on such a block device on multiple servers, without risking data corruption.

Networking to CephFS
--------------------

By default, clusters launched through [magnum-tour](../magnum-tour/README.md) applies `extra_network=cumulus-internal` label which ensures a direct route to the CephFS nodes.

Step 1: Deploy Ceph CSI
-----------------------

Ceph CSI is a dependency of Manila CSI chart. Install it using `helm` v3 client:

    helm repo add ceph-csi https://ceph.github.io/csi-charts
    helm install --namespace kube-system ceph-csi-cephfs ceph-csi/ceph-csi-cephfs

Step 2: Deploy Manila CSI
-------------------------

Now you are ready to deploy Manila CSI which can also be installed using `helm` v3 client:

    helm repo add cpo https://kubernetes.github.io/cloud-provider-openstack
    helm install --namespace kube-system manila-csi cpo/openstack-manila-csi -f values.yaml

For more tunable chart values, see: <https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/manila-csi-plugin/using-manila-csi-plugin.md>

Step 3: Add Manila storage class
--------------------------------

Now, we need to create a `StorageClass` which references appropriate secrets that are able to talk to the OpenStack Manila APIs. In this example we use the Keystone secret called `os-trustee` that was injected by Magnum when it created the cluster into the `kube-system` namespace. Note your OpenStack cluster's Manila service could have a different value for CephFS type files, `cephfsnativetype` is just an example that works on the Cambridge IRIS OpenStack cloud. Additionally, the configuration specified `kernel` mount which is more performant compared to `fuse` mount.

    kubectl apply -f sc.yaml

If you wish to use this as your default storage class:

    kubectl patch storageclass csi-manila-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

Step 4: Add Persistent Volume Claim and Pod
-------------------------------------------------

Now we can proceed to create a Persistent Volume Claim (PVC) that references the StorageClass created in the previous step. Because it is created with the access mode "ReadWriteMany", you are able to attach it to multiple pods that may be spread across multiple nodes. When this is created, the Manila CSI provisioner uses the credentials referenced in the StorageClass to create the file share in Manila:

    kubectl apply -f pvc.yaml

Finally, we create a demo pod that specifies that references the PVC:

    kubectl apply -f pod.yaml

When the pod is ready, you can exec into its shell and observe that the Manila share is mounted into `/var/lib/www`:

    kubectl exec -it new-cephfs-share-pod bash
    ls /var/lib/www

We will continue from this point in the [Spark example](https://github.com/RSE-Cambridge/iris-magnum/tree/master/spark/) by creating a spark cluster which makes use of the Manila share.

Cleaning up
-----------

    kubectl delete -f pod.yaml
    kubectl delete -f pvc.yaml
    kubectl delete -f sc.yaml
    helm delete --namespace kube-system manila-csi
    helm delete --namespace kube-system ceph-csi-cephfs

Troubleshooting
---------------

    kubectl logs ds/ceph-csi-cephfs-nodeplugin -n kube-system -c csi-cephfsplugin
    kubectl logs ds/manila-csi-openstack-manila-csi-nodeplugin -n kube-system -c cephfs-nodeplugin
    kubectl logs ds/manila-csi-openstack-manila-csi-nodeplugin -c cephfs-nodeplugin
    kubectl logs statefulset/manila-csi-openstack-manila-csi-controllerplugin -c cephfs-nodeplugin
