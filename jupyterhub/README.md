JupyterHub
==========

We have two examples for Jupyter Hub. This assumes you have followed the magnum tour. That will have ensured you used terraform v0.12 to create your Kubernetes cluster using OpenStack Magnum, have a correctly configured kubectl and helm3 install that are both pointing your new Kubernetes cluster.

Persistent Volumes in K8s
-------------------------

The JupyterHub example assumes that there is a default storage class available for notebooks to consume.

If you created your cluster following instructions from [magnum-tour](../magnum-tour/README.md), you should be able to use Cinder CSI volumes by creating a default storage class as follows.

    kubectl apply -f cinder-csi-sc.yaml
    kubectl get sc

If you are adapting these instructions and Cinder is not available on your cloud, you can always create an ephemeral NFS server provisioner for this exercise.

    helm repo add kvaps https://kvaps.github.io/charts
    helm upgrade --install nfs-server-provisioner kvaps/nfs-server-provisioner --values nfs-server-provisioner.yaml

Zero to Juypterhub
------------------

At this point, we assume that you have `helm` and `kubectl` clients installed and pointing at your Kubernetes cluster.

We can now follow this tutorial: <https://zero-to-jupyterhub.readthedocs.io/en/latest/jupyterhub/installation.html>

    helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    helm repo update

    cat > jhub.yaml <<END
    proxy:
      secretToken: "`openssl rand -hex 32`"
    END

    helm upgrade --cleanup-on-fail --install jhub jupyterhub/jupyterhub --values jhub.yaml --version 0.11.1

    kubectl --namespace jhub get service

Once the external IP appears you can now login as any username and password. This is clearly an unsafe default for a Public IP address!

If the spawner fails to spawn a Jupyter notebook, it is likely that your PodSecurityPolicy is restrictive. We need to relax the policy for the `jhub` namespace so that kube spawner component of JupyterHub has the permission to spawn privileged initContainers:

    kubectl apply -f psp.yaml
    cat <<END | kubectl apply -f -
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: jhub-rolebinding
      namespace: jhub
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: hub-clusterrole
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:serviceaccounts
    END

    

Once you have tried this out, you can teardown the system by doing this:

    helm delete jhub -n jhub
    kubectl delete namespace jhub
    kubectl delete -f psp.yaml

NOTE: Now you have things running, you can do more advance config of the system, such as offering multiple container images or sizes of containers, by looking at these docs: <https://zero-to-jupyterhub.readthedocs.io/en/latest/jupyterhub/customization.html>

DaskHub
-------

DaskHub (formerly known as Pangeo) is a combination of JupyterHub as a web front end with Dask workers in the backend. In this demo, the login feature integrates with IRIS IAM.

    helm repo add dask https://helm.dask.org
    helm repo update
    helm upgrade --install dhub dask/daskhub --namespace dhub -f dhub.yaml -f iam.yaml --create-namespace --version 2021.3.4

 We need to relax the policy for the `dhub` namespace as we did for `jhub` in the JupyterHub demo:

    kubectl apply -f psp.yaml
    cat <<END | kubectl apply -f -
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: dhub-rolebinding
      namespace: dhub
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: hub-clusterrole
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:serviceaccounts
    END

To get the address of the service used:

    kubectl get svc -n dhub

Note that `iam.yaml` includes the IP address of a precreated floating ip address. This allows for the OIDC configuration to be setup in advance of setting up JupyterHub, and means you get a predictable IP address for the web service. If you want to pick your own floating IP, either update the IP address in `iam.yaml` or remove it and the system will create a new floating IP on your behalf. More details on using OIDC with JupyterHub can be found here: <https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html#authenticating-with-oauth2>

Teardown can be done by:

    helm -n dhub delete dhub
    kubectl delete namespace dhub
    kubectl delete -f psp.yaml
