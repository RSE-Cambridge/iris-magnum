Running Sonobuoy conformance test
=================================

Installing Sonobuoy
-------------------

    VERSION=0.20.0 && \
        curl -L "https://github.com/vmware-tanzu/sonobuoy/releases/download/v${VERSION}/sonobuoy_${VERSION}_linux_amd64.tar.gz" --output sonobuoy.tar.gz && \
        mkdir -p tmp && \
        tar -xzf sonobuoy.tar.gz -C tmp/ && \
        chmod +x tmp/sonobuoy && \
        sudo mv tmp/sonobuoy /usr/local/bin/sonobuoy && \
        rm -rf sonobuoy.tar.gz tmp

    sonobuoy version

        Sonobuoy Version: v0.20.0
        MinimumKubeVersion: 1.17.0
        MaximumKubeVersion: 1.99.99
        GitSHA: f6e19140201d6bf2f1274bf6567087bc25154210
        API Version check skipped due to missing `--kubeconfig` or other error

Configuration and replicating images
------------------------------------

We have a problem due to the Docker rate limits that images fail to pull. Therefore, we will push all images which use images from Dockerhub to use a local registry. We will leave the others as they are for now.

Generate `sonobuoy gen default-image-config > sonobuoy.yml` and modify as follows:

    REGISTRY=harbor.cumulus.openstack.hpc.cam.ac.uk/sonobuoy; cat << EOF > sonobuoy.yml
buildImageRegistry: k8s.gcr.io/build-image
dockerGluster: $REGISTRY #docker.io/gluster
dockerLibraryRegistry: $REGISTRY #docker.io/library
e2eRegistry: gcr.io/kubernetes-e2e-test-images
e2eVolumeRegistry: gcr.io/kubernetes-e2e-test-images/volume
gcRegistry: k8s.gcr.io
promoterE2eRegistry: k8s.gcr.io/e2e-test-images
sigStorageRegistry: k8s.gcr.io/sig-storage
EOF

Pull the required images:

    sonobuoy images pull

Push the required images to our local repo:

    REGISTRY=harbor.cumulus.openstack.hpc.cam.ac.uk/sonobuoy; sonobuoy images push --e2e-repo-config sonobuoy.yml --custom-registry $REGISTRY

Running and submitting conformance result
-----------------------------------------

Run conformance:

    REGISTRY=harbor.cumulus.openstack.hpc.cam.ac.uk/sonobuoy; sonobuoy run --mode=certified-conformance --e2e-repo-config sonobuoy.yml --sonobuoy-image $REGISTRY/sonobuoy:v0.20.0 --systemd-logs-image $REGISTRY/systemd-logs:v0.3

Retrieve results:

    cd k8s-conformance/v1.20/openstack-magnum
    outfile=$(sonobuoy retrieve); mkdir ./results; tar xzf $outfile -C ./results; cp results/plugins/e2e/results/global/* ./

Cleaning up:

    sonobuoy delete --all; rm -rf results/

Further reading
---------------

- <https://github.com/cncf/k8s-conformance/blob/master/instructions.md#running>
