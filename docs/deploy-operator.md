# Observatorium Operator

![Observatorium](https://avatars0.githubusercontent.com/u/51818702?s=100&v=4sanitize=true)

## Prelude

Check the following resources for more information about Observatorium:

* [Observatorium](https://github.com/observatorium/observatorium)
* [Observatorium API](https://github.com/observatorium/api/)
* [Locutus - The framework which the operator is based on](https://github.com/brancz/locutus)

## How to deploy - Kubernetes and OpenShift

In order to ease the installation of Observatorium, an operator is available.

### Prerequisites

#### Create Namespaces

```shell
kubectl create namespace observatorium
```

#### S3 storage endpoint and secret

For **testing purposes** you may use [minio](https://github.com/minio/minio) as described below.

```shell
kubectl create namespace observatorium-minio
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/minio-secret-loki.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/minio-secret-thanos.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/minio-pvc.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/minio-deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/minio-service.yaml
```

#### Dex

For **testing purposes** you may use [dex](https://github.com/dexidp/dex) as an OIDC identity provider for the Observatorium API as described below.

```shell
kubectl create namespace dex
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/tests/manifests/observatorium-xyz-tls-dex.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/dex-secret.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/dex-pvc.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/dex-deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/examples/dev/manifests/dex-service.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/tests/manifests/test-ca-tls.yaml
```

### Deployment

#### Prometheus CRDs - Kubernetes Only

You may skip this step if you are using OpenShift, in which the CRD is already available as a part of the monitoring stack.
```shell
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/136b818c9ac289716ad214df79968c0c8de2ef5b/manifests/setup/0servicemonitorCustomResourceDefinition.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/136b818c9ac289716ad214df79968c0c8de2ef5b/manifests/setup/0prometheusruleCustomResourceDefinition.yaml
```

#### RBAC Configuration

```shell
kubectl apply -f https://raw.githubusercontent.com/observatorium/operator/master/manifests/cluster_role.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/operator/master/manifests/cluster_role_binding.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/operator/master/manifests/service_account.yaml
```

#### Deploy Observatorium CRD and Operator

```shell
kubectl apply -f https://raw.githubusercontent.com/observatorium/operator/master/manifests/crds/core.observatorium.io_observatoria.yaml
kubectl apply -f https://raw.githubusercontent.com/observatorium/operator/master/manifests/operator.yaml
```

## Deploy an example CR

```shell
kubectl apply -n observatorium -f https://raw.githubusercontent.com/observatorium/operator/master/example/manifests/observatorium.yaml
```

For **testing purposes**, you may use the end-to-end test certificate and key as described below.
```shell
kubectl apply -n observatorium -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/tests/manifests/observatorium-xyz-tls-configmap.yaml
kubectl apply -n observatorium -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/tests/manifests/observatorium-xyz-tls-secret.yaml
```

Monitor the CR status and wait for status --> Finished

```shell
kubectl -n observatorium get observatoria.core.observatorium.io observatorium-xyz -o=jsonpath='{.status.conditions[*].currentStatus}'

Finished
```

### Expected Result

```shell
kubectl -n observatorium get all

NAME                                                               READY   STATUS    RESTARTS   AGE
pod/observatorium-xyz-loki-compactor-0                             1/1     Running   0          7m9s
pod/observatorium-xyz-loki-distributor-6cb7c58978-588dz            1/1     Running   0          7m9s
pod/observatorium-xyz-loki-ingester-0                              1/1     Running   0          7m8s
pod/observatorium-xyz-loki-querier-0                               1/1     Running   0          7m10s
pod/observatorium-xyz-loki-query-frontend-6f7bd65b8c-fqlzg         1/1     Running   0          7m9s
pod/observatorium-xyz-observatorium-api-58cd494f48-p7ggc           1/1     Running   0          7m9s
pod/observatorium-xyz-thanos-compact-0                             1/1     Running   6          7m8s
pod/observatorium-xyz-thanos-query-85b9fcb944-h4jdl                1/1     Running   0          7m9s
pod/observatorium-xyz-thanos-query-frontend-6749f85c69-4wtbv       1/1     Running   0          7m8s
pod/observatorium-xyz-thanos-query-frontend-memcached-0            2/2     Running   0          7m9s
pod/observatorium-xyz-thanos-receive-controller-796cd55b58-xlhlw   1/1     Running   0          7m8s
pod/observatorium-xyz-thanos-receive-default-0                     1/1     Running   0          7m9s
pod/observatorium-xyz-thanos-rule-0                                1/1     Running   0          7m9s
pod/observatorium-xyz-thanos-store-memcached-0                     2/2     Running   0          7m9s
pod/observatorium-xyz-thanos-store-shard-0-0                       1/1     Running   6          7m8s

NAME                                                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
service/observatorium-xyz-loki-compactor-grpc               ClusterIP   None            <none>        9095/TCP                        7m9s
service/observatorium-xyz-loki-compactor-http               ClusterIP   10.96.111.103   <none>        3100/TCP                        7m9s
service/observatorium-xyz-loki-distributor-grpc             ClusterIP   None            <none>        9095/TCP                        7m9s
service/observatorium-xyz-loki-distributor-http             ClusterIP   10.96.22.42     <none>        3100/TCP                        7m9s
service/observatorium-xyz-loki-gossip-ring                  ClusterIP   None            <none>        7946/TCP                        7m9s
service/observatorium-xyz-loki-ingester-grpc                ClusterIP   None            <none>        9095/TCP                        7m9s
service/observatorium-xyz-loki-ingester-http                ClusterIP   10.96.246.16    <none>        3100/TCP                        7m9s
service/observatorium-xyz-loki-querier-grpc                 ClusterIP   None            <none>        9095/TCP                        7m9s
service/observatorium-xyz-loki-querier-http                 ClusterIP   10.96.158.162   <none>        3100/TCP                        7m9s
service/observatorium-xyz-loki-query-frontend-grpc          ClusterIP   None            <none>        9095/TCP                        7m9s
service/observatorium-xyz-loki-query-frontend-http          ClusterIP   10.96.188.133   <none>        3100/TCP                        7m9s
service/observatorium-xyz-observatorium-api                 ClusterIP   10.96.239.236   <none>        8081/TCP,8080/TCP               7m9s
service/observatorium-xyz-thanos-compact                    ClusterIP   None            <none>        10902/TCP                       7m9s
service/observatorium-xyz-thanos-query                      ClusterIP   10.96.18.9      <none>        10901/TCP,9090/TCP              7m9s
service/observatorium-xyz-thanos-query-frontend             ClusterIP   10.96.14.90     <none>        9090/TCP                        7m9s
service/observatorium-xyz-thanos-query-frontend-memcached   ClusterIP   None            <none>        11211/TCP,9150/TCP              7m9s
service/observatorium-xyz-thanos-receive                    ClusterIP   10.96.255.25    <none>        10901/TCP,10902/TCP,19291/TCP   7m9s
service/observatorium-xyz-thanos-receive-controller         ClusterIP   10.96.134.145   <none>        8080/TCP                        7m9s
service/observatorium-xyz-thanos-receive-default            ClusterIP   None            <none>        10901/TCP,10902/TCP,19291/TCP   7m9s
service/observatorium-xyz-thanos-rule                       ClusterIP   None            <none>        10901/TCP,10902/TCP,9533/TCP    7m9s
service/observatorium-xyz-thanos-store-memcached            ClusterIP   None            <none>        11211/TCP,9150/TCP              7m9s
service/observatorium-xyz-thanos-store-shard-0              ClusterIP   None            <none>        10901/TCP,10902/TCP             7m9s

NAME                                                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/observatorium-xyz-loki-distributor            1/1     1            1           7m9s
deployment.apps/observatorium-xyz-loki-query-frontend         1/1     1            1           7m9s
deployment.apps/observatorium-xyz-observatorium-api           1/1     1            1           7m9s
deployment.apps/observatorium-xyz-thanos-query                1/1     1            1           7m10s
deployment.apps/observatorium-xyz-thanos-query-frontend       1/1     1            1           7m9s
deployment.apps/observatorium-xyz-thanos-receive-controller   1/1     1            1           7m9s

NAME                                                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/observatorium-xyz-loki-distributor-6cb7c58978            1         1         1       7m9s
replicaset.apps/observatorium-xyz-loki-query-frontend-6f7bd65b8c         1         1         1       7m9s
replicaset.apps/observatorium-xyz-observatorium-api-58cd494f48           1         1         1       7m9s
replicaset.apps/observatorium-xyz-thanos-query-85b9fcb944                1         1         1       7m10s
replicaset.apps/observatorium-xyz-thanos-query-frontend-6749f85c69       1         1         1       7m9s
replicaset.apps/observatorium-xyz-thanos-receive-controller-796cd55b58   1         1         1       7m9s

NAME                                                                 READY   AGE
statefulset.apps/observatorium-xyz-loki-compactor                    1/1     7m9s
statefulset.apps/observatorium-xyz-loki-ingester                     1/1     7m9s
statefulset.apps/observatorium-xyz-loki-querier                      1/1     7m10s
statefulset.apps/observatorium-xyz-thanos-compact                    1/1     7m9s
statefulset.apps/observatorium-xyz-thanos-query-frontend-memcached   1/1     7m9s
statefulset.apps/observatorium-xyz-thanos-receive-default            1/1     7m9s
statefulset.apps/observatorium-xyz-thanos-rule                       1/1     7m9s
statefulset.apps/observatorium-xyz-thanos-store-memcached            1/1     7m9s
statefulset.apps/observatorium-xyz-thanos-store-shard-0              1/1     7m10s
```

## Test

### Expose observatorium API for external traffic

* In Kubernetes

```shell
kubectl -n observatorium patch svc observatorium-xyz-observatorium-api --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'
```

* In OpenShift

```shell
oc -n observatorium expose svc observatorium-xyz-observatorium-api --port=public
```

### (Option A) Transmit Metrics via Remote Write Client

```shell
kubectl -n default apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/tests/manifests/observatorium-xyz-tls-configmap.yaml
kubectl -n default apply -f https://raw.githubusercontent.com/observatorium/observatorium/main/configuration/tests/manifests/observatorium-up-metrics-tls.yaml
kubectl wait --for=condition=complete --timeout=5m -n default job/observatorium-up-metrics-tls
````

Result

```shell
job.batch/observatorium-up-metrics-tls condition met
```

### (Option B) Configure Prometheus Remote Write

* Example taken from CRC (Openshift), Prometheus deployed as a part of the monitoring operator.
* Note: If this is applied to a separate cluster, the url should be dns resolvable.

```shell
cat << EOF | kubectl -n openshift-monitoring apply -f -
apiVersion: v1
data:
  config.yaml: |
    prometheusK8s:
      remoteWrite:
      - url: http://observatorium-api-observatorium.apps-crc.testing/api/metrics/v1/write
      externalLabels:
        demo_spoke_cluster: observatorium_demo
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
EOF
```

### Grafana

Data source is set to query the observatorium-api, which proxies the request to thanos-query.
Thus, the data source URL: `http://observatorium-xyz-observatorium-api.observatorium.svc.cluster.local:8080/api/metrics/v1`

#### Deploy Grafana

```shell
kubectl -n observatorium apply -f https://raw.githubusercontent.com/observatorium/operator/master/docs/grafana/grafana.yaml
kubectl -n observatorium apply -f https://raw.githubusercontent.com/observatorium/operator/master/docs/grafana/grafana-cm.yaml
kubectl -n observatorium apply -f https://raw.githubusercontent.com/observatorium/operator/master/docs/grafana/grafana-svc.yaml
```

#### Expose Grafana for external traffic

* In Kubernetes

```shell
kubectl -n observatorium patch svc grafana --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'
```

* In OpenShift

```shell
oc -n observatorium expose svc grafana
```

#### Browse Grafana

You should now be able to see the 'foo' metric generated by the up client you invoked beforehand.
![Multi Cluster Architecture](./grafana-observatorium.png)

