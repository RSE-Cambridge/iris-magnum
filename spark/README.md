# Spark

Here is an example of creating a spark cluster using
a magnum cluster and a helm chart.

## Alternatives

There are several things we are not doing in this example:

* Using the experimental feature where you can use k8s as a scheduler
  instead of yarn or 'standalone':
  https://spark.apache.org/docs/latest/running-on-kubernetes.html
* Operators that make use of the above property such as:
  https://github.com/radanalyticsio/spark-operator and
  https://github.com/GoogleCloudPlatform/spark-on-k8s-operator
* The now deprecated (and a bit stale) helm chart from the helm community:
  https://github.com/helm/charts/tree/master/stable/spark
* Microsoft folk and update of the above helm chart, that includes Zeppelin
  and Livy:
  https://hub.helm.sh/charts/microsoft/spark
  https://github.com/dbanda/charts/tree/master/stable/spark

Instead we have picked the following helm chart, because it appears
to be the most ready for production, and supports adding volumes to all
of the spark workers:

* https://bitnami.com/stack/spark/helm
* https://github.com/bitnami/charts/tree/master/bitnami/spark

## Install Helm 3

Before continuing, please install Helm 3 on the same machine where you
have kubectl installed and configured:
https://helm.sh/docs/intro/install/

We have chosen to only test with Helm 3, the latest version of helm.
All the charts above are actually written in helm 2 format, however
this appears to work well with Helm 3.

Please note that Magnum uses Helm 2, and its tiller component, to deploy
some of the kubernetes system. Using Helm 3 avoids any conflicts that
can occur with either re-using Magnum tiller or attempting to run two
tiller instances on one kubernetes cluster.

## Demo Spark

We assume you have both kubectl and helm installed and pointing at
your magnum installed cluster.

Next we assume you have run the PVC demo app. This creates the Manila based
Storage Class. This allow the following step to work and create a PVC
that can be used by all the spark workers:

    kubectl create -f bsparkPvc.yml

Now we need to tell helm about where the helm chart lives:

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update

We are now ready to use helm to create the spark cluster, making use
of the PVC we created above.

    helm install bspark bitnami/spark --values bsparkValues.yml --version 1.2.5

For more details on the kinds of values you can specify, look at the examples
that are described here:
https://github.com/bitnami/charts/tree/master/bitnami/spark/#parameters

To update values and apply it to the current cluster you can do this:

    helm upgrade bspark bitnami/spark --values bsparkValues.yml --version 1.2.5

Note there may be newer versions that listed above, but the above version has
been tested with a Magnum cluster.

To teardown the demo system:

    helm delete bspark
    kubectl delete -f bsparkPvc.yml

## Testing Spark

Firstly, you can try spark submit:

    kubectl exec -ti bspark-worker-0 -- spark-submit \
      --master spark://bspark-master-svc:7077 \
      --class org.apache.spark.examples.SparkPi \
      examples/jars/spark-examples_2.11-2.4.4.jar 50

Secondly, you can use the spark shell to test spark can access the storage
that is provided by Manila.

    kubectl exec -ti bspark-worker-0 -- bash -c 'echo foo >/sparkdata/test'

    kubectl exec -ti bspark-worker-0 -- spark-shell \
       --master spark://bspark-master-svc:7077

    scala> val textFile = spark.read.textFile("/sparkdata/test")
    scala> textFile.first()
    scala> textFile.count()
    scala> :quit

Here we see spark is able to access the file that been written onto the
CephFS filesystem.
