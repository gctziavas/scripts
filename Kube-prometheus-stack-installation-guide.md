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
#### Step 3: Verify the Installation
```
kubectl get pods --namespace monitoring
```
#### Step 4: Access the Prometheus UI and Grafana UI
```
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

```
# retrieve the grafana admin user password

kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:3000
```
