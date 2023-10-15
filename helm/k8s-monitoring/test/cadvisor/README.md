### Install cAdvisor

cAdvisor exports the container metrics such as CPU usage, Memory usage, etc.

Kustomized manifests are available. Yes!

`$ kubectl apply -k https://github.com/google/cadvisor//deploy/kubernetes/base`

```
namespace/cadvisor created
serviceaccount/cadvisor created
daemonset.apps/cadvisor created
```
cAdvisor runs as a DaemonSet and collects container information from each Node.
```
$ kubectl -n cadvisor get daemonset -l app=cadvisor

NAME       DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
cadvisor   1         1         1       1            1           <none>          6m54s

$ pod=`kubectl -n cadvisor get pod -l app=cadvisor -o jsonpath="{.items[0].metadata.name}"`
$ kubectl -n cadvisor port-forward pod/"${pod}" 8080:8080

Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080

# from different terminal
$ curl localhost:8080/metrics

# HELP cadvisor_version_info A metric with a constant '1' value labeled by kernel version, OS version, docker version, cadvisor version & cadvisor revision.
# TYPE cadvisor_version_info gauge
cadvisor_version_info{cadvisorRevision="86b11c65",cadvisorVersion="v0.45.0",dockerVersion="",kernelVersion="5.10.124-linuxkit",osVersion="Alpine Linux v3.16"} 1
# HELP container_blkio_device_usage_total Blkio Device bytes usage
# TYPE container_blkio_device_usage_total counter
container_blkio_device_usage_total{container_label_app="",container_label_app_kubernetes_io_component="",container_label_app_kubernetes_io_name="",container_label_app_kubernetes_io_version="",container_label_component="",container_label_controller_revision_hash="",container_label_description="",container_label_io_cri_containerd_kind="",container_label_io_kubernetes_container_name="",container_label_io_kubernetes_pod_name="",container_label_io_kubernetes_pod_namespace="",container_label_io_kubernetes_pod_uid="",container_label_k8s_app="",container_label_maintainers="",container_label_name="",container_label_pod_template_generation="",container_label_pod_template_hash="",container_label_tier="",device="/dev/vda",id="/",image="",major="254",minor="0",name="",operation="Read"} 0 1669642901054
```

Metrics with names like container_** are container metrics.