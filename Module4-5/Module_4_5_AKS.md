

# Module 4 & 5 Lab: AKS - Azure Kubernetes Service


# Module 4: Azure Kubernetes Service (AKS)

*Note:* AKS-Tools.md has all the tools needed to work with AKS'


0. Create AKS Cluster & Review Both Private and Public Clusters 
1. Pod
2. Replica Sets
3. Deployments & Service 
4. Config Maps and Secrets 
5. Namespaces
6. Volumes and Persistence 
7. Network Policy
8. Ingress with GatewayAPI

# 1. Pod 

Folder: ACA_Workshop_Labs/Module4-5/Pod-Deployment-Service

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
## 5. Namespaces

Folder: ACA_Workshop_Labs/Module4-5/Namespace

```bash

kubectl apply -f namespace-marketing.yaml
kubectl get namespace
kubectl get all -n marketing

kubectl apply -f deployment-content-web.yaml
kubectl get all -n marketing 

```

# 6. Volumes and Persistence 

# Storage Classes: Dynamic Provisioning

> **Goal:** Dynamically create an Azure Storage Account and File Share using a Storage Class and PVC — no manual Azure resource creation required.

 
 
Folder: ACA_Workshop_Labs/Module4-5/Persistence/Dynamic-Provisioning



## Step 1 — Create the Storage Class


Folder: ACA_Workshop_Labs/Module4-5/Persistence/StorageClass-DISK

```bash

kubectl apply -f azure-disk-sc.yaml
kubectl get sc   
kubectl apply -f azure-pvc.yaml
kubectl get pvc
kubectl get pv  
kubectl apply -f pod.yaml 
kubectl get pod 
kubectl describe pod my-app-pod


  Mounts:
      /mnt/azure from storage-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-5kdbk (ro)

Volumes:
  storage-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  my-azure-pvc
    ReadOnly:   false


 
```

## Step 2 — Testing the Persistent Volume / Disk 


```bash
 
kubectl exec -it my-app-pod -- /bin/bash

ls mnt/azure
echo "Hello Azure Disk2" > /mnt/azure/myfile2.txt

-----------



# Static Provisioning Demo Steps

> **Note:** This lab assumes you have already created an AKS Cluster.

---

## Prerequisites

Navigate to the working directory:

```bash
cd AKSWorkshop/Lab/Module4/Persistence/Static-Provisioning
```

---

## Step 1 — Capture the MC Resource Group Name

Go to **Azure Portal → Resource Groups** and capture the Resource Group name for your MC AKS cluster.

**Example:**
```
MC_aksworkshopRG_aksworkshopcluster_usgovvirginia
```

---

## Step 2 — Create a Storage Account

Go to **Azure Portal → Storage Accounts → Create**

| Field | Value |
|---|---|
| Name | `staticstorageaccount` |
| Resource Group | `MC_aksworkshopRG_aksworkshopcluster_usgovvirginia` |

Select all default options, then click **Review + Create → Create**.

---

## Step 3 — Create a File Share

Go to **Azure Portal → Storage Accounts → staticstorageaccount**

- Expand **Data storage → Classic File Shares → + File Share**
- Name: `static-file-share`
- Click **Review + Create → Create**

---

## Step 4 — Capture Access Keys

Go to **Security + Networking → Access Keys** and copy the storage account key.

> Ask your instructor for the Secret Command.

---

## Step 5 — Create the Kubernetes Secret

```bash
kubectl create secret generic azure-secret \
  --from-literal=azurestorageaccountname=staticstorageaccount \
  --from-literal=azurestorageaccountkey=<YOUR_ACCESS_KEY>

kubectl get secrets
```

> **Note:** Make sure `azure-secret` was created successfully.

---

## Step 6 — Apply the Persistent Volume

```bash
cd AKSWorkshop/Lab/Module4/Persistence/Static-Provisioning

kubectl apply -f azure-file-pv.yaml
kubectl get pv
```

---

## Step 7 — Apply the Persistent Volume Claim

```bash
kubectl apply -f azure-file-pvc.yaml
```

Expected output:
```
persistentvolumeclaim/azurefile created
```

```bash
kubectl get pvc
```

> **Note:**
> - Status: `Bound`
> - Volume: `azurefile`

```bash
kubectl get pv
```

> **Note:**
> - Status: `Bound`
> - CLAIM set to `default/azurefile`

---

## Step 8 — Deploy the App Pod

```bash
kubectl apply -f app-pod.yaml
kubectl get pods
kubectl describe pod mypod
```

> **Note:** Verify the mount path:
> ```
> Mounts: /mnt/azure from azure (rw)
> ```

---

## Step 9 — Write a File from Inside the Pod

```bash
kubectl exec pod/mypod -it -- /bin/sh
```

From inside the Pod shell:

```sh
ls /mnt/azure
echo "Hello from Azure File Share-Static-Provisioning sharing - Pod" > /mnt/azure/StaticShare.txt
ls /mnt/azure
cat /mnt/azure/StaticShare.txt
```

---

## Step 10 — Verify File in Azure Portal

Go to **Azure Portal → Storage Accounts → staticstorageaccount → Data storage → File Shares → static-file-share → Browse**

You should see the `StaticShare.txt` file created by the Pod.

---

## Step 11 — Edit the File from Azure Portal

- Click the **⋯ (3 dots)** next to `StaticShare.txt`
- Click **Edit**
- Change the content to: `Hello from Azure Portal Storage Account`
- Click **Save**

---

## Step 12 — Verify the Edit from Inside the Pod

```bash
kubectl exec pod/mypod -it -- /bin/sh
```

From inside the Pod shell:

```sh
cat /mnt/azure/StaticShare.txt
```

> You should see the updated content edited from the Azure Portal, confirming that the file share is working bidirectionally.

------------

## 7. Network Policy

Run the below command to enable the NetworkPolicy Azure plug-in

Note: Below updates command takes 10 to 15 minutes

Option # 1: (DO THIS OPTION FOR THE NETWORK POLICY LAB)

 1. Create a Brand new AKS Cluster with below options 
 2. Networking Tab --> Select Network configuration: Azure CNI Overlay
 3. Integration Tab --> Select Network Policy: Select Azure

Option # 2 On Existing cluster: az aks update --resource-group --name --network-policy azure

## Sample Command: 

az aks update --resource-group aksworkshopRG --name aksworkshopcluster --network-policy azure

# Folder: ACA_Workshop_Labs/Module4-5/Networkpolicy

kubectl apply -f deployments.yaml

kubectl get pods -o wide

Capture the frontend running Pod name: frontend-app-67ddc659fd-n55rx

Capture the backend running Pod name: backend-app-7455bc4998-vj2b7

Capture the frontend IP# : 10.244.1.91 

Capture the backend IP# : 10.244.2.223

# Check Connectivity from Frontend to Backend

Frontend >>>>>>  Backend

# External Test
kubectl exec -it frontend-app-67ddc659fd-n55rx  -- curl 10.244.2.223 --max-time 1

# Shell Test 
kubectl exec pod/frontend-app-67ddc659fd-n55rx -it -- /bin/sh


## Output

<title>Welcome to nginx!</title>

......

# Check Connectivity from Backend to Frontend

kubectl exec -it backend-app-7455bc4998-vj2b7 -- curl -sS 10.244.1.91  --max-time 1

Output
<title>Welcome to nginx!</title> <style>


# Apply the Backend Network Policy

# Ingress (BACKEND incoming traffic)
Only pods labeled app: frontend are allowed to send traffic to the backend. Any other pod, external service, or namespace is blocked from reaching the backend.

# Egress (BACKEND outgoing traffic)
The backend can only send traffic to pods labeled app: frontend. It cannot reach the internet, a database, other services, or anything else not labeled as frontend.

# NetworkPolicy # 1 
kubectl apply -f backend-network-policy.yaml
kubectl get networkpolicy
kubectl describe networkpolicy backend-network-policy

## Connectivity test

kubectl exec -it frontend-app-67ddc659fd-n55rx  -- curl 10.244.2.223 --max-time 1
kubectl exec -it backend-app-7455bc4998-vj2b7 -- curl -sS 10.244.1.91  --max-time 1

## Check Connectivity from External Sources

kubectl run busybox --image=busybox --rm -it -- /bin/sh

# First Usecase

# Test frontend connectivity

wget --spider --timeout=1 10.244.1.91 

# Output
Connecting to 10.244.1.91 (10.244.1.91:80)
remote file exists

# Second Usecase
# Second Backend connectivity  

wget --spider --timeout=1 10.244.2.223

# Output for 2 Use Case - 
# Backend will not accept any traffic other than FrontEnd 

Connecting to 10.244.2.223 (10.244.2.223:80)
wget: download timed out

# NetworkPolicy # 2

*Ingress (incoming traffic)* : Only pods labeled app: backend can send traffic into the frontend. No external users, ingress controllers, load balancers, or other pods can reach the frontend.

*Egress (outgoing traffic)* : 

The frontend can only send traffic to pods labeled app: backend. It cannot reach the internet, APIs, DNS, or anything else.


kubectl apply -f frontend-network-policy.yaml
kubectl get networkpolicy
kubectl describe networkpolicy frontend-network-policy

## Check Connectivity from External Sources

kubectl run busybox --image=busybox --rm -it -- /bin/sh

# 1 Usecase Test frontend connectivity - Timeout

wget --spider --timeout=1 10.244.1.91 

# Output

Connecting to 10.244.1.91 (10.244.1.91:80)
wget: download timed out

# 2 Use case Backend connectivity - Timeout
wget --spider --timeout=1 10.244.2.223 

# Output

Connecting to 10.244.2.223 (10.244.2.223:80)
wget: download timed out

---------

Review Other NetworkPolicies: DenyAllEgress, Allow only specific Namespace.

---------



# 8. Ingress with GatewayAPI

## Getting started with Gateway API

https://gateway-api.sigs.k8s.io/guides/getting-started/introduction/

# Kubernetes Gateway API 

# Concepts Overview
Gateway API has three core resource types, each typically owned by a different role:

# 1. GatewayClass

```bash
Owned By: Cluster Admin
Purpose: Defines which controller handles Gateways

```
# 2. Gateway

```bash
Owned By: Cluster Operator
Purpose: Entry point — ports, protocols, listeners

```

# 3. HTTPRoute

```bash

Owned By: Developer
Purpose: Routing rules — paths, hostnames, backends

# HTTP routing Flow

```

# Step 1 — Install the Gateway API CRDs
# The standard release channel includes GA and beta resources (GatewayClass, Gateway, HTTPRoute, ReferenceGrant)

```bash

kubectl apply --server-side -f \
  https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml



```

Verify the CRDs are installed:

```bash
kubectl get crds | grep gateway
# Expected output:
# gateways.gateway.networking.k8s.io
# gatewayclasses.gateway.networking.k8s.io
# httproutes.gateway.networking.k8s.io
# referencegrants.gateway.networking.k8s.io


```

# Step 2 — Install a Gateway Controller
# You need a controller implementation. We'll use NGINX Gateway Fabric (straightforward for local testing). Choose one based on your environment:

```bash
# Install via Helm
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --set service.type=NodePort  # use LoadBalancer on cloud clusters
 



```

## Popular GatwayAPI providers

```bash

 Option A — NGINX Gateway Fabric (recommended for local/general use)
 Option B — Envoy Gateway (CNCF project)
 Option C — kind cluster with Envoy Gateway (full local setup)

 ```

# Option A — NGINX Gateway Fabric (recommended for local/general use)

You need a controller implementation. We'll use NGINX Gateway Fabric (straightforward for local testing). Choose one based on your environment:

```bash
# Install via Helm
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --set service.type=LoadBalancer  # use LoadBalancer on cloud clusters # use NodePort for on-prem

```

# If you want to switch between LoadBalancer vs NodePort 

```bash
helm upgrade ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --set service.type=LoadBalancer
```




Verify the controller pod is running:

```bash
kubectl get pods -n nginx-gateway   # or envoy-gateway-system

```


3 Step 3 — Deploy the Hello World Application
Create your backend app and service:

```bash

# hello-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: hashicorp/http-echo:latest
        args:
          - "-text=Hello from Kubernetes Gateway API!"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world-svc
  namespace: default
spec:
  selector:
    app: hello-world
  ports:
  - port: 80
    targetPort: 5678
  type: ClusterIP


kubectl apply -f hello-app.yaml
kubectl get pods   # wait until Running


```

# Step 4 — Create the GatewayClass
The GatewayClass tells Kubernetes which controller to use. The controllerName must match your installed controller:

```bash

# gatewayclass.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx  # or "eg" for Envoy Gateway
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
  # For Envoy Gateway use: gateway.envoyproxy.io/gatewayclass-controller


----
kubectl apply -f gatewayclass.yaml
kubectl get gatewayclass
# NAME    CONTROLLER                                      ACCEPTED
# nginx   gateway.nginx.org/nginx-gateway-controller     True


```

# Step 5 — Create the Gateway
The Gateway defines the listener — the entry point for traffic:

```bash

# gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: hello-gateway
  namespace: default
spec:
  gatewayClassName: nginx   # must match GatewayClass name above
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same  # only allow HTTPRoutes from this namespace

----

kubectl apply -f gateway.yaml

# Wait for it to be ready
kubectl get gateway hello-gateway
# NAME              CLASS   ADDRESS        PROGRAMMED   AGE
# hello-gateway     nginx   203.0.113.10   True         30s
 

```

# Review the Service and Gateway NGINX Loadbalancer IP
kubectl get service

```bash
#NAME                  TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
#hello-gateway-nginx   LoadBalancer   10.0.224.15   20.158.245.79   80:30173/TCP   27m
#hello-world-svc       ClusterIP      10.0.68.93    <none>          80/TCP         28m
#kubernetes            ClusterIP      10.0.0.1      <none>          443/TCP        9h
```


# Step 6 — Create the HTTPRoute
The HTTPRoute defines the actual routing rules — which paths/hostnames go to which services:

```bash
# httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: hello-route
  namespace: default
spec:
  parentRefs:
  - name: hello-gateway   # binds to our Gateway
  hostnames:
  - "hello.example.com"   # optional: remove to match all hostnames
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /hello
    backendRefs:
    - name: hello-world-svc
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: hello-world-svc
      port: 80

kubectl apply -f httproute.yaml

kubectl get httproute
# NAME          HOSTNAMES              AGE
# hello-route   ["hello.example.com"]  10s




```

# Step 7 — Test It
Get the Gateway's external address:

```bash

export GW_IP=$(kubectl get gateway hello-gateway \
  -o jsonpath='{.status.addresses[0].value}')
echo $GW_IP


```

# Test your routes:

```bash

# Test root path
curl http://$GW_IP/
# Hello from Kubernetes Gateway API!

# Test /hello path
curl http://$GW_IP/hello
# Hello from Kubernetes Gateway API!

# If using hostname matching, set the Host header:

curl -H "Host: hello.example.com" http://$GW_IP/hello

# Hello from Kubernetes Gateway API!

# Review httproute.yaml file 
# / path will also route to hello-world-svc service 
curl -H "Host: hello.example.com" http://$GW_IP/


```

# Step 8 - Add Path-Based Routing for Two Services
A common next step — routing /v1 and /v2 to different backends:

```bash

rules:
- matches:
  - path:
      type: PathPrefix
      value: /v1
  backendRefs:
  - name: hello-v1-svc
    port: 80
- matches:
  - path:
      type: PathPrefix
      value: /v2
  backendRefs:
  - name: hello-v2-svc
    port: 80



```
# GatewayAPI Reference :

 
# Check controller acceptance

kubectl get gatewayclassCheck 

# Listener status

kubectl get gateway

# Check route attachment
kubectl get httproute

# Debug routing issues
kubectl describe httproute hello-route

 







