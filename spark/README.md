Spark
=====

Here is an example of creating a Spark cluster using a Magnum cluster and a helm chart.

We have picked the following Helm chart, because it appears to be the most production ready and supports adding volumes to all of the spark workers:

- <https://bitnami.com/stack/spark/helm>
- <https://github.com/bitnami/charts/tree/master/bitnami/spark>

Spark Demo
----------

We assume you have both `kubectl` and `helm` installed and pointing at your Magnum Kubernetes cluster. See [magnum-tour](../magnum-tour/README.md#install-dependencies) for instructions on how to do this.

Next we assume you have run the PVC demo app. This creates the Manila based Storage Class. This allow the following step to work and create a PVC that can be used by all the spark workers:

    kubectl apply -f pvc.yaml

Now we need to tell helm about where the helm chart lives:

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update

We are now ready to use helm to create the spark cluster, making use of the PVC we created above.

    helm upgrade --install bspark bitnami/spark --values values.yaml --version 5.4.0   

For more details on the kinds of values you can specify, look at the examples that are described here: <https://github.com/bitnami/charts/tree/master/bitnami/spark/#parameters>

To update values and apply it to the current cluster you can re-run the command above.

Note there may be newer versions that listed above, but the above version has been tested with a Magnum cluster.

To teardown the demo system:

    helm delete bspark
    kubectl delete -f pvc.yml

Testing Spark
-------------

Firstly, you can try spark submit:

    kubectl exec -ti bspark-worker-0 -- spark-submit \
      --master spark://bspark-master-svc:7077 \
      --class org.apache.spark.examples.SparkPi \
      examples/jars/spark-examples_2.12-3.1.1.jar 50

Secondly, you can use the spark shell to test spark can access the storage that is provided by Manila.

    kubectl exec -ti bspark-worker-0 -- bash -c 'echo foo >/sparkdata/test'

    kubectl exec -ti bspark-worker-0 -- spark-shell \
       --master spark://bspark-master-svc:7077

    scala> val textFile = spark.read.textFile("/sparkdata/test")
    scala> textFile.first()
    scala> textFile.count()
    scala> :quit

Here we see spark is able to access the file that been written onto the CephFS filesystem.

Further reading
---------------

Using an experimental feature, you can use k8s as a scheduler instead of yarn or 'standalone':
- <https://spark.apache.org/docs/latest/running-on-kubernetes.html>

Operators that make use of the above property such as:
- <https://github.com/radanalyticsio/spark-operator and>
- <https://github.com/GoogleCloudPlatform/spark-on-k8s-operator>

Microsoft folk and update of the above helm chart, that includes Zeppelin and Livy:
- <https://hub.helm.sh/charts/microsoft/spark>
- <https://github.com/dbanda/charts/tree/master/stable/spark>
