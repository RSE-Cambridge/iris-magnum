# JupyterHub

We have two examples for Jupyter Hub. This assumes you have followed the magnum tour.
That will have ensured you used terraform v0.12 to create your Kubernetes cluster
using OpenStack Magnum, have a correctly configured kubectl and helm3 install that are
both pointing your new Kubernetes cluster.

## Cinder Volumes in K8s

Assuming your magnum templated enabled the built in cinder volumes, you
can use them for PVCs by create a new storage class:

    cat <<END | kubectl apply -f -
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: cinder
      annotations:
    provisioner: kubernetes.io/cinder
    END

You can make it the default by applying:

    kubectl patch storageclass cinder -p \
      '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

Note: the above uses the in-tree cinder driver that is deprecated. We are
looking to change OpenStack Magnum to rely on the more supported setup
of using the cloud-provider-openstack based driver. But for now, this seems
to be the best way to use cinder volumes.

## Zero to Juypterhub

At this point you will have Helm installed and kubectl pointing at your
kubernetes cluster created by OpenStack Magnum.

To make it easy to tidy up and separate your work, we create a new namespace
to contain all the work on JupyterHub:

    kubectl create namespace jhub

We can now follow this tutorial:
https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html

    helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    helm repo update

    cat >config.yml <<END
    proxy:
      secretToken: "`openssl rand -hex 32`"
    END

    helm install jhub jupyterhub/jupyterhub --values config.yml --namespace jhub

    kubectl --namespace jhub get service

Once the external IP appears you can now login as any username and password.
This is clearly an unsafe default for a Public IP address!

Once you have tried this out, you can teardown the system by doing this:

    helm ls --namespace jhub
    kubectl --namespace jhub get all

    helm uninstall jhub -n jhub
    kubectl delete namespace jhub

Note: with Kube>=1.16.x we seem to be missing the fix for this issue:
https://github.com/jupyterhub/kubespawner/issues/354

## Pangeo

Pangeo is a great demo of a web front end in front of Dask.

    helm repo add pangeo https://pangeo-data.github.io/helm-chart/
    helm repo update

    kubectl create namespace pangeo

    cat >pangeo.yml <<END
    proxy:
      secretToken: "`openssl rand -hex 32`"
    END

    helm install ptest pangeo/pangeo --namespace=pangeo -f pangeo.yml -f iam.yml --version 20.01.15-e3086c1

To get the address of the service used:

    kubectl get svc -n pangeo

Note that iam.yml includes the IP address of a precreated floating ip address.
This allows for the OIDC configuration to be setup in advance of setting up
the Jupyter hub, and means you get a predictable IP address for the web service.
If you want to pick your own floating ip, either update the ip address in iam.yml
or remove it and the system will create a floating ip on your behalf.

Teardown can be done by:

    helm --namespace pangeo delete ptest
    kubectl delete namespace pangeo
