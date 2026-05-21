

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

## Review Other NetworkPolicies: DenyAllEgress, Allow only specific Namespace.



