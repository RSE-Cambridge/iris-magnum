#!/bin/sh

# manila-provisioner
kubectl create -f ./rbac.yaml && kubectl create -f ./deployments.yaml
# storage class and persistent volume claim
kubectl create -f ./sc.yaml && kubectl create -f ./pvc.yaml
# use the PVC
kubectl create -f demo.yaml
