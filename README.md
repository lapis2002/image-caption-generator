# image-caption-generator
MLOps for Image Caption Generator.

- terraform
- log in to cluster & switch context
- create namespaces
- install nginx-ingress
- install model
- update /etc/hosts

```

ACCOUNT=$(gcloud info --format='value(config.account)')
kubectl create clusterrolebinding prometheus-cluster-admin \
    --clusterrole cluster-admin \
    --user $ACCOUNT```
