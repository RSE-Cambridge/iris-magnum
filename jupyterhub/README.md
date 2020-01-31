# JupyterHub

We have two examples for Jupyter Hub.

## Zero to Juypterhub

At this point you will have Helm installed and kubectl pointing at your
kubernetes cluster created by OpenStack Magnum.

We can now follow this tutorial:
https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html

    helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    helm repo update

    helm install jhub jupyterhub/jupyterhub --values config.yml

    kubectl get service

This relies on having a default PVC Storage class configured, as described
in our Manila PVC tutorial.

## Pangeo

Pangeo is a great demo of a web front end in front of Dask.

    helm repo add pangeo https://pangeo-data.github.io/helm-chart/
    helm repo update

    WIP here:
    https://github.com/brtknr/pangeo/tree/cumulus/openstack
