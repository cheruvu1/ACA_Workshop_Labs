

# Module 4 & 5 Lab: AKS - Azure Kubernetes Service


# Module 4: Azure Kubernetes Service (AKS)

*Note:* AKS-Tools.md has all the tools needed to work with AKS'


1. Pod
2. Replica Sets
3. Deployments
4. Config Maps and Secrets 
5. Namespaces

# Module 5: Intermediate Kubernetes Topics

6. Volumes and Persistence 
7. Multi-Container Pods and Init Containers 
8. Ingress with GatewayAPI
9. HELM Package Manager 
10. Network Policy
11. Horizontal Pod Auto Scaler (HPA)



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


# Deploy the Deployment Object
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

- TEST
http://20.158.225.100:3000


```


```bash

```

```bash

```




```bash

```