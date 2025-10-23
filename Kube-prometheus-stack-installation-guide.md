#### Step 1: Add the Helm Repository
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

```
#### Step 2: Install the Helm Chart
##### Option A: with node-exporter
```
helm install kube-prometheus-stack \
--create-namespace \
--namespace monitoring \
prometheus-community/kube-prometheus-stack
```
##### Option B: without node-exporter
```
nano values.yaml
```
In values.yaml add:
```
# Use nodeExporter to disable the sub-chart
nodeExporter:
	enabled: false
```
save values.yaml and run:
```
helm install kube-prometheus-stack\
--create-namespace \
--namespace monitoring \
-f values.yaml \
prometheus-community/kube-prometheus-stack
```

##### Option C: with NodePort Services
Create a values file with NodePort configuration:
```
nano values-nodeport.yaml
```
Add the following configuration:
```yaml
# Prometheus NodePort configuration
prometheus:
  service:
    type: NodePort
    nodePort: 30090  # Choose port between 30000-32767

# Grafana NodePort configuration
grafana:
  service:
    type: NodePort
    nodePort: 30300  # Choose port between 30000-32767

# Alertmanager NodePort configuration (optional)
alertmanager:
  service:
    type: NodePort
    nodePort: 30093  # Choose port between 30000-32767

# Optional: disable node-exporter
# nodeExporter:
#   enabled: false
```
Install with NodePort configuration:
```
helm install kube-prometheus-stack \
--create-namespace \
--namespace monitoring \
-f values-nodeport.yaml \
prometheus-community/kube-prometheus-stack
```

#### Step 3: Verify the Installation
```
kubectl get pods --namespace monitoring
```
Verify NodePort services:
```
kubectl get svc -n monitoring | grep NodePort
```

#### Step 4: Access the Prometheus UI and Grafana UI

##### Option 1: Using Port-Forward (Original method)
```
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

```
# retrieve the grafana admin user password

kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:3000
```

##### Option 2: Using NodePort (if configured)
Get the node IP address:
```
kubectl get nodes -o wide
```

Access services using NodePort:
- Prometheus: `http://<NODE-IP>:30090`
- Grafana: `http://<NODE-IP>:30300` (default username: admin)
- Alertmanager: `http://<NODE-IP>:30093`

Retrieve Grafana admin password:
```
kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

#### Step 5: Update Existing Installation to NodePort (Optional)
If you already have kube-prometheus-stack installed and want to change to NodePort:
```
helm upgrade kube-prometheus-stack \
--namespace monitoring \
-f values-nodeport.yaml \
prometheus-community/kube-prometheus-stack
```
