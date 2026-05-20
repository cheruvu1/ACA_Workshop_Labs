

# Module 4 & 5 Lab: AKS - Azure Kubernetes Service


# Module 4: Azure Kubernetes Service (AKS)

*Note:* AKS-Tools.md has all the tools needed to work with AKS'


0. Create AKS Cluster 
1. Pod
2. Replica Sets
3. Deployments & Service 
4. Config Maps and Secrets 
5. Namespaces

# Module 5: Intermediate Kubernetes Topics

6. Volumes and Persistence 
7. Multi-Container Pods and Init Containers 
8. Ingress with GatewayAPI
9. HELM Package Manager 
10. Network Policy
11. Horizontal Pod Auto Scaler (HPA)
12. Create Private AKS Cluster / Connect 


cd /ACA_Workshop_Labs/Module4-5/Pod-Deployment-Service


# 1. Pod 

### Attach ACR to AKS cluster

```bash

az aks update --name acs-workshop-aks-cluster --resource-group module4-rg --attach-acr myacrlab16284 

```


# Deploy the Pod Object 
```bash

kubectl apply -f version-one-pod.yaml
kubectl apply -f service-version-one.yaml
 
kubectl get pods 
kubectl describe pod version-one-pod 
kubectl logs version-one-pod 

# To Delete a Pod (Optional)
kubectl delete pod content-web-pod  

```

# Deploy the Service Object 

```bash

kubectl apply -f service-version-one.yaml
kubectl get service

```

# Test the Service Object 

```bash

kubectl get service
kubectl get service service-version-one
kubectl describe service service-version-one

curl http://<Replace with LB IP>:80  

Browser: curl http://<Replace with LB IP>:80  


```


# Deploy the Deployment & Replica Set Object

# 1. Deploy the Content-web Microservice

```bash

kubectl apply -f deployment-content-web.yaml

kubectl get deployments
kubectl describe deployment content-web-deployment

kubectl get rs
kubectl get pods

# To Delete the Deployment (Optional)
kubectl delete deployment content-web-deployment

```

# Deploy the Service Object 

```bash
kubectl apply -f service-content-web.yaml
kubectl get services
kubectl describe service content-web-service

```
- TEST
http://<LB IP>:3000
Note: Test the speakers and sessions tabs 


# 2. Deploy the Content-api Microservice

```bash

kubectl apply -f deployment-content-api.yaml 


kubectl get deployments
kubectl describe deployment content-api-deployment

kubectl get rs 
kubectl get pods

# To Delete the Deployment (Optional)
kubectl delete deployment content-api-deployment

```

# Deploy the Content-api Service Object 

```bash

kubectl apply -f service-content-api.yaml
kubectl get services
kubectl describe service content-api-service

```

# 4. Deploy Config Maps and Secrets 

1. Environment Variables
2. ConfigMap
3. Secrets

1. Environment Variables

Folder: ACA_Workshop_Labs/Module4-5/EnvironmentVariables

```bash
kubectl apply -f Pod-Environment-Variable.yaml

kubectl get pod payment-processing-pod-env
kubectl describe pod payment-processing-pod-env

Note: Check the Environment: section

```
2. ConfigMap

Folder: ACA_Workshop_Labs/Module4-5/ConfigMap

```bash

kubectl apply -f AppConfigMap.yaml

kubectl get configmap

kubectl describe configmap payment-processing-config

kubectl apply -f Pod-AppConfigMap.yaml

kubectl get pods

kubectl describe pod payment-processing-pod-configmap

Note:

Environment Variables from: payment-processing-config ConfigMap


```
3. Secrets

Folder: ACA_Workshop_Labs/Module4-5/Secrets


DATABASE_HOST: PlatformOne.DOD.com:7643/ironbankdb
DATABASE_USER_NAME: azure
DATABASE_PASSWORD: stack


```bash

# Basic Base64 Encoding
echo -n 'PlatformOne.DOD.com:7643/ironbankdb' | base64
echo -n 'azure' | base64
echo -n 'stack' | base64

# Decode
echo -n "UGxhdGZvcm1PbmUuRE9ELmNvbTo3NjQzL2lyb25iYW5rZGI=" | base64 --decode
echo -n "YXp1cmU=" | base64 --decode
echo -n "c3RhY2s=" | base64 --decode


kubectl apply -f AppSecrets.yaml
kubectl get secrets
kubectl describe secrets oracle-database-secret

Note: Data is encrypted

```

## How to use Secrets and ConfigMap in a Pod/Deployment

```bash

kubectl apply -f Pod-AppSecrets.yaml
kubectl get pods
kubectl describe pod frontend-pod-secret

```



```bash

```
```bash

```
```bash

```
