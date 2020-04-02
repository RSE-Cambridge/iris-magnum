Magnum Tour
===========

This example goes through creating a magnum cluster using Terraform and connecting to it. We assume the existence of a template created by your OpenStack operator.

Next we give you an overview of what to expect from the default template offered on IRIS Scientific OpenStack clouds. This includes looking at the built in monitoring and load balancing.

Finally we look at exposing servers via ingress.

Creating a Kubernetes (k8s) cluster
-----------------------------------

While you can create your cluster via the Horizon web interface for OpenStack, we recommend using Terraform to create, resize and destroy your k8s clusters.

In this repo we include an example Terraform module to make it easier for you to try using Magnum.

First ensure you have a working OpenStack CLI environment, that includes both python-openstackclient and python-magnumclient. This needs to be run on a Linux environment (such as Windows WSL) that has access to the OpenStack APIs. For IRIS at Cambridge, the APIs have public IP addresses, so you can run this on any Linux box with access to the internet:

```
virtualenv ~/.venv
. ~/.venv/bin/activate
pip install -U pip
pip install -U python-openstackclient python-magnumclient python-octaviaclient
```

To access Kubernetes, you will need to install kubectl on a machine that will have access to the Kubernetes API. Using the default templates at Cambridge IRIS the Kubernetes API is accessed via a public IP address: https://kubernetes.io/docs/tasks/tools/install-kubectl/

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

To access OpenStack APIs using the CLI you can create application credentials using OpenStack Horizon (ensuring to click the button marked as dangerous to allow magnum to create credentials that are passed to Kubernetes) that are downloaded as a clouds.yaml file. You can then do something like this to test everything is working correctly:

```
cp ~/Downloads/clouds.yml .
export OS_CLOUD=openstack
openstack coe cluster template list
```

To create the cluster, you can try the Terraform example here:

```
cd terraform/examples/cluster
terraform init # first time only
terraform plan
terraform apply
```

It will tell you where your kubectl config file has been placed. You can use this to tell kubectl where your cluster lives:

```
export KUBECONFIG=~/.kube/my-test/config
kubectl version
kubectl get all -A
```

If you are not using Terraform, you can call the same OpenStack CLI command that Terraform uses to get hold of the kubectl config file:

```
openstack coe cluster list
openstack coe cluster config <name-of-your-cluster>
```

Once you cluster is up and running you can create a hello world deployment then expose it as a public service via a load balancer:

```
kubectl create deployment hello-node \
  --image=gcr.io/hello-minikube-zero-install/hello-node
kubectl expose deployment hello-node --type=LoadBalancer --port=8080
kubectl get all
```

Once the loadbalancer is created, you should see the external IP that you can use to access the hello world web app on port 8080. You can see what is happening by calling:

```
openstack loadbalancer list
```

If you don't want to wait for OpenStack Octavia to create your loadbalancer you can access the service by using kubectl port-forward:

```
kubectl port-forward svc/hello-node 9000:8080
```

While the above command is running, you can now access the hello world app in your local browser via http://localhost:9000

To delete the demo app, you can do the following:

```
kubectl delete service hello-node
kubectl delete deployment hello-node
```

Finally you can delete your cluster via Terraform:

```
terraform destroy
```

Note that the above can only remove what Terraform added. In particular, its possible to leave behind loadbalancers, cinder volumes and manila shares created by cloud-provider-openstack if you do not first remove all the things deployed on your Kubernetes cluster.

Monitoring
----------

Magnum setups up Prometheus and Grafana to monitor your cluster. You can access it via kubectl port forwarding:

```
kubectl port-forward -n kube-system svc/prometheus-operator-grafana 9000:80
```

That will allow you to access it via http://localhost:9000 with the default user:admin password:admin combination. Allowing you to change the password to something better before exposing it outside the cluster.

In a similar way you can access the prometheus console and node exporter:

```
kubectl port-forward -n kube-system svc/prometheus-prometheus 9090:9090
```

Cluster Networking Overview
---------------------------

To see how Magnum sits in your OpenStack project's networking, have a look at your network topology, after having created a Kubernetes cluster using Magnum:

https://cumulus.openstack.hpc.cam.ac.uk/project/network_topology/

Magnum generates a configuration file that tells kubectl where to access the Kubernetes API. Typically the API is exposed via an OpenStack Octavia load balancer, that has a public IP address assigned from the Magnum external network. Note the master node also makes use of an etcd loadbalancer to allow for a multi-master setup.

All the minions and master nodes are connected to a private network that Magnum has created. It has a router that is used to connect out the external network.

### Exposing services via a LoadBalancer

The hello world example above exposes a service via a load balancer. Each service gets its own Octavia load balancer, which consumes an external IP address.

### Debugging ClusterIP services via kubectl port-forward

Taking the hello world example we can instead expose the service only within the cluster, using the ClusterIP type:

```
kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
kubectl expose deployment hello-node --type=ClusterIP --port=8080
kubectl get svc/hello-node
kubectl port-forward svc/hello-node 9000:8080
```

While the proxy is running, you can now access it in your local browser via http://localhost:9000

You can delete it by doing the following:

```
kubectl delete service hello-node
kubectl delete deployment hello-node
```

Exposing services via Ingress
-----------------------------

Ingress allows multiple services to share a single IP address and port combination, similar to how traditional shared web hosting can work. This can help you reduce the number of public IP addresses you consume.

For this demo we use nginx ingress, however we instal it manually so it makes use of a load-balancer service type. First you need to install Helm3, then you can run:

```
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm install -n kube-system ingress stable/nginx-ingress --set rbac.create=true
```

You can find more information about install ingress here: https://kubernetes.github.io/ingress-nginx/deploy/#using-helm

First we can find out the public IP address given to the ingress controller:

```
kubectl --namespace kube-system get services ingress-nginx-ingress-controller -o jsonpath={.status.loadBalancer.ingress[*].ip}
```

From this we can work out a possible way to access services via DNS:

```
echo hello.`kubectl --namespace kube-system get services ingress-nginx-ingress-controller -o jsonpath={.status.loadBalancer.ingress[*].ip}`.nip.io
```

At the moment you will get a 404 response from http, and https endpoints associated with the about DNS name. The next step is to make use of ingress to access a service. As an example, lets expose Grafana via ingress:

```
cat <<END | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
    rules:
      - host: "grafana.`kubectl --namespace kube-system get services ingress-nginx-ingress-controller -o jsonpath={.status.loadBalancer.ingress[*].ip}`.nip.io"
        http:
          paths:
            - path: "/"
              backend:
                  serviceName: prometheus-operator-grafana
                  servicePort: 80
END
```

In a similar way we can add the hello world service on the same IP:

```
kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
kubectl expose deployment hello-node --type=ClusterIP --port=8080

cat <<END | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: hello-node
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
    rules:
      - host: "hello.`kubectl --namespace kube-system get services ingress-nginx-ingress-controller -o jsonpath={.status.loadBalancer.ingress[*].ip}`.nip.io"
        http:
          paths:
            - path: "/"
              backend:
                  serviceName: hello-node
                  servicePort: 8080
END
```

To remove the above ingress entries and hello world service:

```
kubectl delete ingress hello-node -n default
kubectl delete ingress grafana-ingress -n kube-system
kubectl delete service hello-node
kubectl delete deployment hello-node
```

If you want to remove the nginx ingress controller from the system:

```
helm delete -n kube-system ingress
```
