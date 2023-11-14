# image-caption-generator
MLOps for Image Caption Generator.

- terraform
- log in to cluster & switch context
- create namespaces
- install nginx-ingress
- install model
- update /etc/hosts

## Monitoring Systems

### Prometheus + Grafana

#### Install [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

* **Get Helm Repository Info**
```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```
* **Exposing monitoring applications at web context**
To expose Prometheus, AlertManager, and Grafana at the same domain with different web contexts, we need to overwrite the default [`values.yaml`](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml) with our custom file `kube-prometheus-stack.expanded.yaml` ([source](https://fabianlee.org/2022/07/02/prometheus-exposing-prometheus-grafana-as-ingress-for-kube-prometheus-stack/)).
```yaml
grafana:
  env:
    GF_SERVER_ROOT_URL: http://icg.monitoring.com/grafana
    GF_SERVER_SERVE_FROM_SUB_PATH: 'true'
  # username is 'admin'
  adminPassword: prom-operator
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/rewrite-target: /$2
    hosts: ['icg.monitoring.com']
    path: "/grafana"
``` 
* **Install Helm Chart**
  Install `kube-prometheus-stack` and overwrite with our custom file:
```sh
helm install -f helm/k8s-monitoring/kube-prometheus-stack.expanded.yaml kube-prometheus-stack prometheus-community/kube-prometheus-stack
```

* **Update Cluster IP to `etc/hosts`**
  Add the Cluster IP to `ect/hosts`, then Grafana can be accessed at `icg.monitoring.com/grafana`
