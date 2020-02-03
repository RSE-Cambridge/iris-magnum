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

You can deleted it by doing the following:

   kubectl delete service hello-node
   kubectl delete deployment hello-node

Finally you can delete your cluster via terraform:

   terraform destroy

## Cluster Overview

Networking overview.

## Exposing services via Ingress

TODO, how to use ngnix ingress instead of octavia loadbalancer
