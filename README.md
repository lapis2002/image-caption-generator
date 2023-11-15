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
  ![grafana_dashboard](assets/images/Screenshot%20from%202023-11-14%2023-42-33.png)

## CI/CD with Jenkins in GCE

### Create Google Compute Engine

* **Create Service Account with Compute Admin Role**

  - Create a new service account with [Compute Admin](https://cloud.google.com/compute/docs/access/iam#compute.admin) role.
  - Create new key of the created service account and download it as json file.
  ![Key of Service Account](assets/images/Screenshot%20from%202023-11-14%2017-18-26.png)
  - Save it in `ansible/secrets`. Update the [service_account_file](https://github.com/lapis2002/image-caption-generator/blob/dev/ansible/playbooks/create_compute_instance.yaml#L14) in `ansible/playbook/create_compute_instance.yaml` with the secret json file.

* **Create the Compute Engine**

```sh
ansible-playbook ansible/playbooks/create_compute_instance.yaml
```

* **Update the ssh key**

  - Generate a new SSH key
    ```ssh-keygen```
  - Add the SSH key to Setting/Metadata/SSH KEYS
  ![SSH Key](assets/images/Screenshot%20from%202023-11-14%2017-32-17.png)
  - Update the [inventory file](https://github.com/lapis2002/image-caption-generator/blob/dev/ansible/inventory) with the External IP address of the compute instance created in the previous step and the path to the ssh key file.
    ![update inventory](assets/images/Screenshot%20from%202023-11-14%2017-34-50.png)

* **Install Jenkin on GCE**
  ```sh
  ansible-playbook -i ansible/inventory ansible/playbooks/deploy_jenkins.yaml
  ```
  ![Install Jenkin](assets/images/Screenshot%20from%202023-11-14%2017-39-52.png)

* **Connect to Jenkins UI**
  - Checking Jenkins installed successfully on GCE
    - Access the GCE instance
      ```
      ssh -i ~/.ssh/id_rsa YOUR_USERNAME@INSTANCE_EXTERNAL_IP
      ```
    - Verify if Jenkins is running
      ```
      sudo docker ps
      ```
  - Access Jenkins UI via `INSTANCE_EXTERNAL_IP:8081`.
  - Follow the instruction to log in into Jenkins.
  - The password can be retrieved by
    ```

    # inside GCE instance
    sudo docker exec -ti jenkins bash
    cat /var/jenkins_home/secrets/initialAdminPassword
    ```
* **Connect Jenkins to GitHub Repo**
  - Add Jenkins to Repo Webhook
    - Payload URL would `http://INSTANCE_EXTERNAL_IP:8081//github-webhook/`
    ![Webhook](assets/images/Screenshot%20from%202023-11-14%2017-49-49.png)
    - Event Trigger can be set to: *Pushes* and *Pull Requests*
  - Add GitHub Repo to Jenkins
    - Create a new Personal Access Token
    - Create new Multibranch Item in Jenkins
    - Connect Repo to Jenkins

* **Add DockerHub Token to Jenkins Credential**
    - Create a new DockerHub Token
    - Add the token to Jenkins' Credentials

* **Install the Kubernetes, Docker, Docker Pineline, GCloud SDK Plugins at `Manage Jenkins/Plugins`**

* **Setup Cloud Connection**
  
  - Create `clusterrolebinding`
  ```
    kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=system:anonymous
    kubectl create clusterrolebinding cluster-admin-default-binding --clusterrole=cluster-admin --user=system:serviceaccount:model-serving:default
  ```
  - Configure clouds at `http://INSTANCE_EXTERNAL_IP:8081/manage/configureClouds/`
    - Get `Kubernetes URL` and `Kubernetes server certificate key`
      ```
      cat ~/.kube/config
      ``` 
      ```
      clusters:
        - cluster:
            certificate-authority-data: KUBERNETES_SERVER_CERTIFICATE_KEY
            server: KUBERNETES_URL
      ```
    ![K8s Cloud Jenkins](assets/images/Screenshot%20from%202023-11-14%2018-10-57.png)

* **Build**
  - When there's new push/pull request, it will build and push the new version of image to DockerHub, then deploy the application with the latest image from DockerHub to GKE cluster.
  ![build](assets/images/Screenshot%20from%202023-11-14%2018-17-58.png)

## Demo

### API

### Grafana