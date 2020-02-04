# Magnum Tour

This example goes through creating a magnum cluster using
terraform and connecting to it.
We assume the existence of a template created by your
OpenStack operator.

Next we give you an overview of what to expect from the default
template offered on IRIS Scientific OpenStack clouds.
This includes looking at the built in monitoring and load balancing.

Finally we look at exposing servers via ingress.

## Creating k8s cluster

While you can create your cluster via the Horizon web interface for
OpenStack, we recommend using terraform to create, resize and destroy
your k8s clusters.

In this repo we include an example terraform module to make it easier
for you to try using Magnum.

First ensure you have a working openstack CLI environment, by trying:

    openstack coe container template list

To create the cluster, you can try the terraform example here:

    cd examples/cluster
    terraform plan
    terraform apply

It will tell you where your kubectl config file has been placed. You can use
this to tell kubectl where your cluster lives:

    export KUBECONFIG=~/.kube/my-test/config
    kubectl get all -A

Once you cluster is up and running you can create a hello world deployment
then expose it as a public service via a load balancer:

    kubectl create deployment hello-node \
      --image=gcr.io/hello-minikube-zero-install/hello-node
    kubectl expose deployment hello-node --type=LoadBalancer --port=8080
    kubectl get all

Once the loadbalancer is created, you should see the external IP that you
can use to access the hello world web app.

You can delete it by doing the following:

    kubectl delete service hello-node
    kubectl delete deployment hello-node

Finally you can delete your cluster via terraform:

    terraform destroy

Note that the above can only remove what terraform added. In particular, its
possible to leave behind loadbalancers, cinder volumes and manila shares
created by cloud-provider-openstack if you do not first remove all the
things deployed on your kubernetes cluster.

## Monitoring

Magnum setups up Prometheus and Grafana to monitor your cluster.
You can access it via kubectl port forwarding:

    kubectl port-forward -n kube-system svc/prometheus-operator-grafana 9000:80

That will allow you to access it via http://localhost:9000 with the default
user:admin password:admin combination. Allowing you to change the password
to something better before exposing it outside the cluster.

In a similar way you can access the prometheus console and node exporter:

    kubectl port-forward -n kube-system svc/prometheus-prometheus 9090:9090

## Cluster Networking Overview

Magnum generates a configuration file that tells kubectl where to access the
kubernetes API. Typically the API is exposed via an OpenStack Octavia load
balancer, that has a public IP address assigned from the Magnum external
network. Note the master node also makes use of an etcd loadbalancer to allow
for a multi-master setup.

All the minions and master nodes are connected to a private network that
Magnum has created. It has a router that is used to connect out the external
network.

### Exposing services via a LoadBalancer

The hello world example above exposes a service via a load balancer. Each
service gets its own Octavia load balancer, which consumes an external IP
address.

### Debugging ClusterIP services via kubectl port-forward

Taking the hello world example we can instead expose the service only
within the cluster, using the ClusterIP type:

    kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
    kubectl expose deployment hello-node --type=ClusterIP --port=8080
    kubectl get svc/hello-node
    kubectl port-forward svc/hello-node 9000:8080

While the proxy is running, you can now access it in your local browser
via http://localhost:9000

You can delete it by doing the following:

    kubectl delete service hello-node
    kubectl delete deployment hello-node

## Exposing services via Ingress

Ingress allows multiple services to share a single IP address and port
combination, similar to how traditional shared web hosting can work.

WARNING: this guide doesn't work as-is.

TODO:Need either LoadBalancer or FloatingIp extra to make this work.

TODO: need to cover HTTPS in more detail.

It is then necessary to label your node of choice as an ingress node, we are going to label the one that matches `minion-0`:

    kubectl label `kubectl get nodes -o NAME | grep node-0 | awk '{ print $1}'` role=ingress

As an example, you can now proceed to map an Ingress to a service in the same Kubernetes namespace as follows:

    cat <<END | kubectl apply -f -
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: grafana-ingress
      namespace: monitoring
      annotations:
        kubernetes.io/ingress.class: "nginx"
    spec:
        rules:
          - host: "grafana.`kubectl get nodes -l role=ingress -o jsonpath={.items[*].status.addresses[?\(@.type==\"ExternalIP\"\)].address}`.nip.io"
            http:
              paths:
                - backend:
                      serviceName: prometheus-operator-grafana
                      servicePort: 80
                  path: "/"
    END

You will also need to ensure that the security group rules allow access to HTTP endpoints.

    for name in `openstack security group list -c Name -f value | grep minion`; do openstack security group rule create --ingress $name --dst-port 80 --protocol tcp; done
