# Module 2 / Day 2 Lab: Azure Container Apps

## Azure Container Apps Demo Topics

1. Deploy the Container to Azure Container Apps
2. Explore Image Deployment Strategies
3. Explore Hosting Options (Ingress Settings)
4. Advanced Ingress — Traffic Splitting (Blue/Green & Canary Deployments)
5. Advanced Networking — IP Restrictions
6. Scalability in Container Apps (replicas)
7. Environment Variables
 

---

## 1. Deploy the Container to Azure Container Apps

### 1.1 Create the Container App

There are two ways to create an Azure Container App. Choose one option below.

**Option 1: Create via Azure Portal**

Navigate to the [Azure Portal](https://portal.azure.com) and use the Container Apps creation wizard.

**Option 2: Create via Azure CLI (using registry credentials)**

*Note: *
Azure Container Apps Environment: 
- A Container Apps Environment is a secure boundary around one or more container apps and jobs. 
- The Container Apps runtime manages each environment by handling OS upgrades, scale operations, failover procedures, and resource balancing.

Workload Profiles in Azure Container Apps:
- A workload profile determines the type and amount of compute and memory resources available to container apps deployed in an Azure Container Apps environment. 
- You can configure different profiles to fit the different needs of your applications.

1. Consumption Profile: Consumption profiles use a serverless architecture.

2. Dedicated Profile: Dedicated profiles run on reserved compute resources in your own dedicated pool. 

3. Flexible Profile (Preview): The Flexible profile blends the billing and setup simplicity of the Consumption profile with many of the performance characteristics of the Dedicated profile


Step1: Azure Container Apps Environment: container-env-19

```bash
RESOURCE_GROUP="container-app-rg-19"

ENV_NAME="container-env-19"

APP_NAME="mycontainerapp19"

ACR_LOGIN_SERVER="myacrlab18.azurecr.us"


ACR_USER=ACA > Settings > Access keys > Enable Admin User > User Name
ACR_PASS=password or password2 

ACR_USER=" "
ACR_PASS=" "


Step2: Deploy the container app 

az containerapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image "$ACR_LOGIN_SERVER/mycontainerapp:1.0-amd64" \
  --target-port 80 \
  --ingress external \
  --registry-server "$ACR_LOGIN_SERVER" \
  --registry-username $ACR_USER \
  --registry-password $ACR_PASS
```

> **Note:** The registry password is stored as a secret (e.g., `myacrlab16284azurecrus-myacrlab16284`). Review it under **Security > Secrets** in the portal.


### 1.2 Verify the Deployment

```bash
az containerapp show \
  -n $APP_NAME \
  -g $RESOURCE_GROUP \
  --query "properties.configuration.ingress.fqdn" \
  -o tsv
```

> **Example output:** `my-container-app.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us`

### 1.3 Additional Deployments

Explore more Container Apps deployment patterns in the [workshop guide](https://moaw.dev/workshop/?src=gh:yelghali/azure-container-apps-lab-beginners/main/docs/#3-push-the-image-to-azure-container-registry).

---

## 2. Explore Image Deployment Strategies

### 2.1 Using Registry Credentials (Username/Password)

This approach is quick to set up but stores credentials as secrets. Suitable for dev/test environments.

```bash
APP_NAME="my-container-app"

az containerapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image "$ACR_LOGIN_SERVER/mycontainerapp:1.0-amd64" \
  --target-port 80 \
  --ingress external \
  --registry-server "$ACR_LOGIN_SERVER" \
  --registry-username $ACR_USER \
  --registry-password $ACR_PASS
```

---

## 2.2 Using Managed Identity ⭐ (Recommended for Production)

Managed Identity eliminates the need to store credentials entirely.

**Step 1: Create the Container App without a registry**

```bash
APP_NAME="mi-container-app"

az containerapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress external
```

**Step 2: Enable System-Assigned Identity and grant AcrPull**

In the portal, go to **Security > Identity > System Assigned > Status: ON**, then run:

Capture the object ID: 275dbd33-b4f0-45ef-ae9f-2006f1ef2491

```bash
# Get the managed identity's principal ID
PRINCIPAL_ID=$(az containerapp show \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query identity.principalId -o tsv)

echo $PRINCIPAL_ID

# Get the ACR resource ID
ACR_ID=$(az acr show --name $ACR_LOGIN_SERVER --query id -o tsv)

echo $ACR_ID

# Assign AcrPull role to the managed identity
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --scope $ACR_ID \
  --role AcrPull
```

**Step 3: Attach ACR using the managed identity**

```bash
az containerapp registry set \
  -n $APP_NAME \
  -g $RESOURCE_GROUP \
  --server $ACR_LOGIN_SERVER \
  --identity system
```

> **Expected output:**
>
> ```json
> [
>   {
>     "identity": "system",
>     "passwordSecretRef": "",
>     "server": "myacrlab16284.azurecr.us",
>     "username": ""
>   }
> ]
> ```

---

### 2.3 Using a Public Registry (No Auth — e.g., DockerHub)

Use this approach when pushing to a public container registry.

```bash
# 1. Build the image
docker build --platform=linux/amd64 -t mycontainerapp:1.0-amd64 .

# 2. Verify the image exists
docker images

# 3. Tag for DockerHub
docker tag mycontainerapp:1.0-amd64 cheruvu007/mycontainerapp:1.0-amd64

# 4. Log in to DockerHub
docker login
# Follow the device confirmation prompt, then open:
# https://login.docker.com/activate

# 5. Push to DockerHub
docker push cheruvu007/mycontainerapp:1.0-amd64
```

---
Azure Container Apps — Aspire Dashboard
 
The Aspire Dashboard provides a developer-centric, live view of the telemetry for all container apps within a Container Apps environment, all in a simple UI interface.

It makes it easier to diagnose issues across the container environment by displaying data of the current session with minimal delay.

---

## 3. Explore Hosting Options (Ingress Settings)

Azure Container Apps supports three ingress modes:

| Mode | Accessibility | Use Case |
|------|--------------|----------|
| **External** | Public internet | Web apps, public HTTP APIs |
| **Internal** | Within the ACA environment / VNet only | Microservices, private backends |
| **None** | No endpoint | Background jobs, event-driven processing |

### 3.1 Create an App with External Ingress (Public)

```bash
APP_NAME_EXTERNAL="container-app-external"

az containerapp create \
  --name $APP_NAME_EXTERNAL \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress external
```

### 3.2 Create an App with Internal Ingress

```bash
APP_NAME_INTERNAL="container-app-internal"

az containerapp create \
  --name $APP_NAME_INTERNAL \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress internal
```

**Get the internal FQDN:**

```bash
az containerapp show \
  --name $APP_NAME_INTERNAL \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  -o tsv
```

> **Example output:** `container-app-internal.internal.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us`

**Test connectivity from another container app:**

Using Portal: ACA > Monitoring > Console > /bin/sh
curl https://container-app-internal.internal.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us

```bash
# Exec into the mi-container-app container
az containerapp exec \
  --name mi-container-app \
  --resource-group $RESOURCE_GROUP \
  --command "/bin/sh"

# Inside the container, test the internal endpoint
curl https://container-app-internal.internal.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us
```

### 3.3 Create an App with No Ingress

```bash
APP_NAME_NOINGRESS="container-app-noingress"

az containerapp create \
  --name $APP_NAME_NOINGRESS \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress external

# Disable ingress after creation
az containerapp ingress disable \
  -n $APP_NAME_NOINGRESS \
  -g $RESOURCE_GROUP
```

---

## 4. Advanced Ingress — Traffic Splitting (Blue/Green & Canary Deployments)

**Blue-Green:** Route all traffic to v1 (blue), deploy v2 (green), then switch 100% at once.  
**Canary:** Gradually shift a small percentage of traffic to v2 while monitoring stability.

### 4.1 Build and Push Version 2

```bash

cd ACA_Workshop_Labs/Module1/web
ACR_LOGIN_SERVER=myacrlab18.azurecr.us
# Login to ACR
az login (if you already executed earlier, you can ignore)
az acr login --name $ACR_LOGIN_SERVER

# Build v2
docker build --platform=linux/amd64 -t mycontainerapp:2.0-amd64 .

# Test locally
docker run -d -p 8080:80 mycontainerapp:2.0-amd64

# Open http://localhost:8080 to verify

# Stop the local container when done
docker stop $(docker ps -q --filter ancestor=mycontainerapp:2.0-amd64)

# Tag and push to ACR
docker tag mycontainerapp:2.0-amd64 $ACR_LOGIN_SERVER/mycontainerapp:2.0-amd64

az acr login --name $ACR_LOGIN_SERVER
docker push $ACR_LOGIN_SERVER/mycontainerapp:2.0-amd64

# Verify in ACR
az acr repository list --name $ACR_NAME -o table
```

> Verify the new image appears in the **Azure Portal** under your Container Registry.

### 4.2 Enable Multiple Revisions Mode

*Note : * Check the current revision mode: Application > Revisions and replicas > Choose revision mode.


To run both versions simultaneously, switch to multiple revision mode:

*Note:* You need a working V1 Azure Container App should be running

```bash

APP_NAME="my-container-app"

az containerapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image "$ACR_LOGIN_SERVER/mycontainerapp:1.0-amd64" \
  --target-port 80 \
  --ingress external \
  --registry-server "$ACR_LOGIN_SERVER" \
  --registry-username $ACR_USER \
  --registry-password $ACR_PASS

```

```bash
az containerapp revision set-mode \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --mode multiple
```

> In the portal: **Application > Revisions and Replicas > Choose Revision Mode**

### 4.3 Deploy the New Revision (v2)

```bash
az containerapp update \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --image "$ACR_LOGIN_SERVER/mycontainerapp:2.0-amd64"
```

This creates a new revision running v2 while keeping v1 active.

**List revisions to get their names:**

```bash
az containerapp revision list -n $APP_NAME -g $RESOURCE_GROUP -o table
```

### 4.4 Canary Deployment Model: Split Traffic Between Revisions

Replace the revision names below with actual values from the list above:

```bash
REV1="my-container-app--0000001"
REV2="my-container-app--aetvm2b"

az containerapp ingress traffic set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --revision-weight $REV1=10 $REV2=90
```

> This routes 10% of traffic to v1 and 90% to v2. Verify the split in the **Azure Portal**.

---

## 5. Advanced Networking — IP Restrictions

IP restrictions let you control which clients can reach your container app's public endpoint.

| Mode | Behavior |
|------|----------|
| **Allow** | Only listed IPs are permitted; all others are blocked |
| **Deny** | Listed IPs are blocked; all others are permitted |

> **Important:** You cannot mix Allow and Deny rules on the same app — choose one mode.

### 5.1 Add an IP Allow Rule

```bash
# Get your current public IP
MY_IP=$(curl -s ifconfig.me)
echo $MY_IP

# Create an allow rule for your IP only
az containerapp ingress access-restriction set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --rule-name "AllowMyIP" \
  --description "Allow only my current IP" \
  --ip-address "${MY_IP}/32" \
  --action Allow

# Verify the rule was created
az containerapp ingress access-restriction list \
  -n $APP_NAME \
  -g $RESOURCE_GROUP \
  -o table
```

### 5.2 Test the IP Restriction

Access the app from a different network or device to confirm it is blocked.

### 5.3 Remove an IP Allow Rule

```bash
az containerapp ingress access-restriction remove \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --rule-name "AllowMyIP"
```

### 5.4 Add an IP Deny Rule

```bash
az containerapp ingress access-restriction set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --rule-name "BlockXIp" \
  --description "Block attacker IP" \
  --ip-address "104.190.161.168/32" \
  --action Deny
```

> To remove via portal: **Networking > Ingress > Source Restrictions**

---
# 6. Scalability in Container Apps

## Core Concepts

- **Horizontal Scaling** — Container apps scale out by creating new on-demand instances called **replicas**
- **Default State** — When you first create a container app, the scale rule is set to **zero**
- **Cost** — No charges are incurred when an application scales to zero

## Types of Scaling Rules

| Type | Description |
|---|---|
| **HTTP Traffic** | Scales based on the number of concurrent HTTP requests to your revision |
| **Event Driven** | Event-based triggers such as messages in an Azure Service Bus |
| **CPU / Memory** | Scales based on the amount of CPU or memory consumed by a replica |

---

## Lab: HTTP Traffic Based Scale Out

### Step 1 — Configure Scaling in Azure Portal

1. Login to Azure Portal → **replicas-demo** → Application → **Scale**
2. Set **Min replicas** = `0`
3. Set **Max replicas** = `5`
4. Click **+ Add** under Scale Rules and configure:
   - **Rule name:** `http-rule`
   - **Type:** HTTP scaling
   - **Concurrent requests:** `20`
5. Save as a new revision

---

### Step 2 — Install Apache JMeter (Mac)

| Action | Command |
|---|---|
| Install | `brew install jmeter` |
| Reinstall | `brew reinstall jmeter` |
| Open | `open /opt/homebrew/Cellar/jmeter/5.6.3/bin/jmeter` |

---

### Step 3 — Configure JMeter

1. Right-click **Test Plan** → Add → **Thread Group**
2. Right-click **Thread Group** → Add → Sampler → **HTTP Request**
3. Right-click **Thread Group** → Add → Listener → **View Results Tree**
4. Configure the HTTP Request:
   - **Protocol:** `https`
   - **Server Name or IP:** `container-app-external.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us`
5. Set **Thread Group** → Number of Threads (Users): `400`

---

### Step 4 — Test & Monitor

- Run the test via **View Results Tree**
- In Azure Portal: **Monitoring** → **Log Stream** → Console → Refresh → use **Replica Drop Down** to review active replicas
- Review **Revisions and Replicas** in the portal to confirm scaling behavior
 
---

# 7. Environment Variables in Container Apps

## Review and Manage Environment Variables

### Portal Path

**Container App** → Application → **Containers** → Edit and Deploy → Select the Container Image → **Environment Variables** → **+ Add**

### Steps

1. Navigate to your **Container App** in the Azure Portal
2. Go to **Application** → **Containers**
3. Click **Edit and Deploy**
4. Select your **Container Image**
5. Click **Environment Variables**
6. Click **+ Add** to add a new environment variable


# 8.0 Deploy an express container app using the Azure CLI (preview)

*Note* 
During preview, express is available only in the West Central US and East Asia regions.

1. Before you begin, upgrade the Azure Container Apps CLI extension to the required version.

```bash
az upgrade

```
2. Add the Container Apps extension.

```bash
az extension add -n ContainerApp

```
3. Update the extension to ensure you have the latest version.

```bash
az extension update --name containerapp

```
# Create an express environment

Create a resource group and an express environment. Replace <ENVIRONMENT_NAME> and <RESOURCE_GROUP> with your own values.


```bash

az containerapp env create --environment-mode express --name <ENVIRONMENT_NAME> --resource-group <RESOURCE_GROUP> --logs-destination none

```
# Deploy a container app

Deploy a container image to the express environment.

```bash

az containerapp up --image docker.io/nginx --name <APP_NAME> --resource-group <RESOURCE_GROUP>

```




