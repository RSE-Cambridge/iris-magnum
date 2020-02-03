# JupyterHub

We have two examples for Jupyter Hub.

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
      secretToken: `openssl rand -hex 32`
    END

    helm install jhub jupyterhub/jupyterhub --values config.yml --namespace jhub

    kubectl --namespace jhub get service

Once the external IP appears you can now login as any username and password.
This is clearly an unsafe default for a Public IP address!

Once you have tried this out, you can teardown the system by doing this:

    helm ls --namespace jhub
    kubectl --namespace jhub get all

    helm delete jhub --purge
    kubectl delete namespace jhub

## Pangeo

Pangeo is a great demo of a web front end in front of Dask.

    helm repo add pangeo https://pangeo-data.github.io/helm-chart/
    helm repo update

    WIP here:
    https://github.com/brtknr/pangeo/tree/cumulus/openstack
