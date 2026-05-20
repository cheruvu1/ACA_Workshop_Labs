# Module 3 / Day 3 Lab: Azure Container Apps — Advanced Topics

---

## Azure Container Apps Demo Topics

1. Bring Your Own Virtual Network (VNET)
2. Secrets Management
3. Azure Key Vault Integration
4. Authentication and Authorization
5. Logging and Observability

---

# Content Web & Content API — Docker Build & Deployment Guide

This guide covers local development, Docker image builds for ARM64 (local) and AMD64 (Linux/production),
and pushing images to Azure Container Registry (ACR).

---

## Overview

| Service | Local Port | Description |
|---|---|---|
| **Content Web** | `3000` | Frontend web application |
| **Content API** | `3001` | Backend API serving sessions and speakers data |

---

## Part 1 — Content Web

Go to Folder: ACA_Workshop_Labs/Module3/OwnVNET-Example/content-web


### 1.1 Run Locally (Without Docker)

Start the Node.js server directly on your machine:

```bash
node ./server.js &
```

> The `&` runs the server in the background so your terminal stays free.

Test in your browser:

```
http://localhost:3000
```

To stop the Node.js server at any time:

```bash
killall node
```

> **Note:** `killall node` removes **all** running Node.js processes on your local machine.

---

### 1.2 Build Docker Image (Basic)

```bash
docker build -t content-web .
```

---

### 1.3 Local Testing on ARM Laptop (Apple M1/M2/M3)

Build the image for the ARM64 architecture to match your local chip:

```bash
docker build --platform=linux/arm64 -t content-web:1.0-arm64 .
```

Run the container locally:

```bash
docker run -p 3000:3000 content-web:1.0-arm64
```

Test in your browser:

```
http://localhost:3000
```

---

### 1.4 Push to ACR (Linux AMD64 — Production)

Azure Container Apps runs on **Linux AMD64**, so a separate image must be built for that platform before pushing.

**Step 1 — Build for AMD64:**

```bash
docker build --platform=linux/amd64 -t content-web:1.0-amd64 .
```

**Step 2 — Tag the image for ACR:**

```bash
docker tag content-web:1.0-amd64 myacrlab16284.azurecr.us/content-web:1.0-amd64
```

**Step 3 — Login to ACR:**

```bash
az acr login --name myacrlab16284.azurecr.us
```

**Step 4 — Push the image:**

```bash
docker push myacrlab16284.azurecr.us/content-web:1.0-amd64
```

---

## Part 2 — Content API

Go to Folder: ACA_Workshop_Labs/Module3/OwnVNET-Example/content-api 

### 2.1 Run Locally (Without Docker)

Start the Node.js API server directly on your machine:

```bash
node ./server.js &
```

Test in your browser:

```
http://localhost:3001
```

To stop the Node.js server at any time:

```bash
killall node
```

---

### 2.2 Build Docker Image (Basic)

```bash
docker build -t content-api .
```

---

### 2.3 Local Testing on ARM Laptop (Apple M1/M2/M3)

Build the image for ARM64 architecture:

```bash
docker build --platform=linux/arm64 -t content-api:1.0-arm64 .
```

Run the container locally:

```bash
docker run -p 3001:3001 content-api:1.0-arm64
```

Test the API endpoints in your browser or via curl:

```
http://localhost:3001/sessions
http://localhost:3001/speakers
```

---

### 2.4 Push to ACR (Linux AMD64 — Production)

**Step 1 — Build for AMD64:**

```bash
docker build --platform=linux/amd64 -t content-api:1.0-amd64 .
```

**Step 2 — Tag the image for ACR:**

```bash
docker tag content-api:1.0-amd64 myacrlab16284.azurecr.us/content-api:1.0-amd64
```

**Step 3 — Login to ACR:**

```bash
az acr login --name myacrlab16284.azurecr.us
```

**Step 4 — Push the image:**

```bash
docker push myacrlab16284.azurecr.us/content-api:1.0-amd64
```

---

## Quick Reference — Full Command Summary

### Content Web

```bash
# Run locally
node ./server.js &

# Build (ARM64 - local Mac)
docker build --platform=linux/arm64 -t content-web:1.0-arm64 .
docker run -p 3000:3000 content-web:1.0-arm64

# Build & Push (AMD64 - ACR/Production)
docker build --platform=linux/amd64 -t content-web:1.0-amd64 .
docker tag content-web:1.0-amd64 myacrlab16284.azurecr.us/content-web:1.0-amd64
az acr login --name myacrlab16284.azurecr.us
docker push myacrlab16284.azurecr.us/content-web:1.0-amd64

# Stop local Node server
killall node
```

### Content API

```bash
# Run locally
node ./server.js &

# Build (ARM64 - local Mac)
docker build --platform=linux/arm64 -t content-api:1.0-arm64 .
docker run -p 3001:3001 content-api:1.0-arm64

# Test API endpoints
# http://localhost:3001/sessions
# http://localhost:3001/speakers

# Build & Push (AMD64 - ACR/Production)
docker build --platform=linux/amd64 -t content-api:1.0-amd64 .
docker tag content-api:1.0-amd64 myacrlab16284.azurecr.us/content-api:1.0-amd64
az acr login --name myacrlab16284.azurecr.us
docker push myacrlab16284.azurecr.us/content-api:1.0-amd64

# Stop local Node server
killall node
```

---

## Key Concepts

| Term | Explanation |
|---|---|
| `--platform=linux/arm64` | Builds image for Apple Silicon (M1/M2/M3) chips |
| `--platform=linux/amd64` | Builds image for standard Intel/AMD Linux servers used by Azure |
| `docker tag` | Renames/labels an image to match the ACR repository path before pushing |
| `az acr login` | Authenticates Docker with your Azure Container Registry |
| `docker push` | Uploads the tagged image to ACR |
| `killall node` | Stops all running Node.js processes on your local machine |

---

## Why Two Platforms?

Your **local Mac (ARM64)** and **Azure Linux servers (AMD64)** use different CPU architectures.
A Docker image built for ARM64 will not run on AMD64 and vice versa.
This is why two separate builds are needed — one for local testing and one for production deployment.



# 1. Bring Your Own Virtual Network (VNET)

# Azure Container Apps — Real-World Networking Scenarios

## Overview

By default, Azure Container Apps runs in a managed network. This guide walks through connecting your Container App to your own Virtual Network (VNET) for private networking scenarios.

---

## Scenario Description

| App | Role | Access |
|---|---|---|
| **Content-Web** | UI Application | Accessible over the internet (public IP) |
| **Content-API** | Backend API | Accessible only inside the Container App environment (internal) |

---

## Prerequisites & Supporting Resources

| Resource | Details |
|---|---|
| Docker Images | `content-web` and `content-api` — built and pushed to ACR |
| Azure Container Registry | `myacrlab16284.azurecr.us` |

---

## Azure Resource Details

### ACA VNET — `container-apps-vnet`

| Setting | Value |
|---|---|
| Resource Group | `aca_resourcegroup` |
| Name | `container-apps-vnet` |
| Subnet 1 | `web-subnet` — with NSG rules for Container Apps |
| Subnet 2 | `app-subnet` — with NSG rules for Container Apps |

---

## Step 1: Create the Virtual Network

In the Azure Portal, create a VNet named `container-apps-vnet` with the subnets and NSG rules defined above.

---

## Step 2: Create the Content-Web Container App

### Basic Settings

| Field | Value |
|---|---|
| Subscription | `<Your Subscription>` |
| Resource Group | `ACA-Vnet-Demo-RG` |
| Name | `content-web` |
| Deployment Source | Container Image |

### Environment

| Field | Value |
|---|---|
| Environment Name | `public-env` |

### Workload Profile

| Field | Value |
|---|---|
| Profile Name | `publicwlpro` |
| Size | Dedicated-D4 |
| Min Instances | `1` |
| Max Instances | `3` |

### Networking Tab

| Field | Value |
|---|---|
| Public Network Access | **Enabled** — allows incoming traffic from the internet |
| Use your own virtual network | **Yes** |
| Virtual Network | `container-app-vnet` |
| Subnet | `web-subnet` |
| Virtual IP | **External** — exposes hosted apps on an internet-accessible IP |

### Container Tab

| Field | Value |
|---|---|
| Image Source | ACR |
| Registry | `myacrlab16284.azurecr.us` |
| Image | `content-web` |
| Image Tag | `1.0-amd64` |
| Workload Profile | `publicwlpro` |

### Ingress Tab

| Field | Value |
|---|---|
| Ingress | Enabled |
| Ingress Traffic | Accept traffic from anywhere |
| Target Port | `3000` |

Click **Review + Create** → **Create**.

### ✅ Test Content-Web

**Azure Portal → Container Apps → `content-web` → Overview → Application URL**

> ⚠️ The **Speakers** and **Sessions** tabs will show no data — Content-API has not been deployed yet.

---

## Step 3: Create the Content-API Container App

### Basic Settings

| Field | Value |
|---|---|
| Subscription | `<Your Subscription>` |
| Resource Group | `ACA-Vnet-Demo-RG` |
| Name | `content-api` |
| Deployment Source | Container Image |
| Environment | `public-env` |

### Container Tab

| Field | Value |
|---|---|
| Registry | `myacrlab16284.azurecr.us` |
| Image | `content-api` |
| Image Tag | `1.0-amd64` |
| Workload Profile | `publicwlpro` |

### Ingress Tab

| Field | Value |
|---|---|
| Ingress | Enabled |
| Traffic | **Limited to Container Apps Environment** |
| Target Port | `3001` |

Click **Review + Create** → **Create**.

### ✅ Test Content-API

**Azure Portal → Container Apps → `content-api` → Overview → Application URL**

Since Content-API is not publicly accessible, you will see:

```
Error 404 - This Container App is stopped or does not exist.
```

> This is expected — Content-API is internal only.

---

## Step 4: Connectivity Test (Content-Web → Content-API)

Verify internal connectivity via the Content-Web console.

**Navigate to:** ACA: `content-web` → Monitoring → Console → `/bin/sh` → **Connect**

Run the following curl commands:

```sh
# Test speakers endpoint
curl https://content-api.internal.braveplant-1a740dc9.usgovvirginia.azurecontainerapps.us/speakers

# Test sessions endpoint
curl https://content-api.internal.braveplant-1a740dc9.usgovvirginia.azurecontainerapps.us/sessions
```

---

## Step 5: Configure Content-API URL as an Environment Variable

Link Content-Web to Content-API by setting an environment variable.

**Navigate to:** ACA: `content-web` → Application → Containers → **Edit and Deploy** → Container Image → select `content-web` → **Environment Variables**

| Field | Value |
|---|---|
| Name | `CONTENT_API_URL` |
| Source | Manual Entry |
| Value | `https://content-api.internal.braveplant-1a740dc9.usgovvirginia.azurecontainerapps.us` |

Click **Save** → **Create**. A new revision will be deployed automatically.

**Verify:** Containers → Environment Variables → Based on revision: *New revision*

---

## Step 6: Final Validation

**Azure Portal → Container Apps → `content-web` → Overview → Application URL**

> ✅ The **Speakers** and **Sessions** tabs should now display live data successfully.

---

## Architecture Summary

```
Internet
    │
    ▼
[ content-web ]  ←── public-env (container-apps-vnet / web-subnet)
    │                 Virtual IP: External
    │ internal DNS
    ▼
[ content-api ]  ←── public-env (container-apps-vnet / app-subnet)
                      Ingress: Limited to Container Apps Environment
```

 

---

## 2. Secrets Management

### Comparison: Environment Variables vs. Secrets vs. Azure Key Vault

| Feature | Environment Variables | ACA Secrets | Azure Key Vault |
|---|---|---|---|
| Sensitive data | ❌ Not designed for it | ✅ Yes | ✅ Yes |
| Scope | Container-level | App-level | Cross-service |
| Shared across containers | ❌ No | ✅ Yes | ✅ Yes |
| Shared across Azure services | ❌ No | ❌ No | ✅ Yes (VMs, AKS, Functions, ACA) |
| Best for | Non-sensitive config | App-scoped secrets | Centralized secrets at scale |

> **Key rule:** If you change, add, or modify a secret, you must restart the container/revision for the change to take effect.

### Lab: Deploy an App with Secrets

**Deploy the secrets demo app:**

```bash
environment="my-containerapps-env"

az containerapp create \
  --name secrets-demo-app \
  --resource-group $RESOURCE_GROUP \
  --environment $environment \
  --image myacrlab16284.azurecr.us/secretsdemo:latest \
  --target-port 80 \
  --ingress external \
  --secrets key1=123456 key2="Another secret"
```

**Reference secrets as environment variables (Portal):**

1. **Portal > Container Apps > `secrets-demo-app` > Security > Secrets** — verify secrets were created
2. **Overview** — test the application URL (secrets not yet visible)
3. **Application > Containers > Environment Variables > Edit and Deploy**
   - Click the container `secrets-demo-app`
   - Set suffix: `v2`
   - Add environment variables:
     - `key1` → Reference a Secret → `key1`
     - `key2` → Reference a Secret → `key2`
4. **Save > Create** — a new revision `secrets-demo-app--v2` is deployed
5. **Revisions and Replicas > `secrets-demo-app--v2`** — test the app URL (secrets not yet updated)
6. **Restart the revision** to apply the secrets:

```bash
az containerapp revision restart \
  -n secrets-demo-app \
  -g $RESOURCE_GROUP \
  --revision secrets-demo-app--v2
```

1. Test the app URL again — secrets should now be visible
2. **Monitoring > Console > run `printenv`** — review `KEY1` and `KEY2`

**Optional cleanup:**

```bash
az group delete --resource-group $RESOURCE_GROUP --yes
```

 ----

 # 3. Azure Key Vault Integration

> Covers referencing Key Vault secrets as environment variables in Azure Container Apps.

---

## Step 1 — Create the Secrets Demo ACA Application

### Set Environment Variables

```bash
environment="my-containerapps-env"
RESOURCE_GROUP="aca_resourcegroup"
ACR_NAME="myacrlab16284.azurecr.us"
ACR_USER=" "
ACR_PASS=" "
```

### Login to Azure and ACR

```bash
az login
az acr login --name $ACR_NAME
az acr login --name myacrlab16284.azurecr.us
```

### Create the Container App

```bash
az containerapp create \
  --name keyvault-demo-app \
  --resource-group $RESOURCE_GROUP \
  --environment $environment \
  --image myacrlab16284.azurecr.us/secretsdemo:latest \
  --target-port 80 \
  --ingress external \
  --registry-server "$ACR_NAME" \
  --registry-username $ACR_USER \
  --registry-password $ACR_PASS
```

---

## Step 2 — Create an Azure Key Vault

1. Go to **Azure Portal** → Search **Key vaults** in the top search bar
2. Click **+ Create** and configure:
   - **Name:** `secrets-demo-keyvault`
3. Click **Create**

---

## Step 3 — Add Key 1 in ACA Secrets

1. Go to **Azure Portal** → **ACA** → **keyvault-demo-app** → Security → **Secrets** → **+ Add**
2. Configure:
   - **Key:** `key1`
   - **Value:** `ThisIsaACASecret`
3. Click **Add**

---

## Step 4 — Add Key 2 in Azure Key Vault

### Assign Permissions to Yourself First

> **Note:** First time you open Key Vault Secrets, you will see:
> *"You are unauthorized to view these contents."*
> You must assign yourself permissions before proceeding.

1. Go to **secrets-demo-keyvault** → **Access Control (IAM)** → **+ Add** → **Add role assignment**
2. Configure:
   - **Role:** `Key Vault Secrets Officer`
   - **Assign access to:** User, group, or service principal
   - **Members:** Select your profile
3. Click **Review + assign**

> **Key Vault Secrets Officer** — Performs any action on the secrets of a key vault.

### Create the Secret

1. Go to **secrets-demo-keyvault** → Objects → **Secrets**
2. Click **+ Generate/Import** and configure:
   - **Upload options:** Manual
   - **Name:** `key2`
   - **Secret value:** `secretfromkeyvault`
3. Click **Create**

---

## Step 5 — Enable Managed Identity on the Container App

> In order for ACA to access Azure Key Vault, it requires permissions via a **Managed Identity**.

1. Go to **ACA** → **keyvault-demo-app** → Security → **Identity**
2. Set **System Assigned** → **On** → **Save** → **Yes**
3. Capture the **Object (Principal) ID:**
   ```
   dc0cc547-7a85-41bc-a373-defb54eceae1
   ```

> **Note:** This creates a Service Principal in Entra ID (App Registration) in the background.

### Assign Key Vault Role to Managed Identity

1. Click **Add role assignments** → **+ Add role assignment (Preview)**
2. Configure:
   - **Scope:** Key Vault
   - **Subscription:** Your Subscription ID
   - **Resource:** `secrets-demo-keyvault`
   - **Role:** `Key Vault Secrets User`
3. Click **Save**

> **Key Vault Secrets User** — Able to fetch secrets from the Key Vault service.

---

## Step 6 — Add Key 2 as a Key Vault Reference in ACA Secrets

1. Go to **ACA** → **keyvault-demo-app** → Security → **Secrets** → **+ Add**
2. Configure:
   - **Key:** `key2`
   - **Type:** Key Vault reference
   - **Managed Identity:** System assigned

### Get the Secret Identifier URL

1. Go to **Key Vault** → **secrets-demo-keyvault** → Objects → Secrets → **key2** → Current Version
2. Copy the **Secret Identifier:**
   ```
   https://secrets-demo-keyvault.vault.usgovcloudapi.net/secrets/key2/79907b2845ea4d32beb1aa4c680a8940
   ```
3. Paste into **Key Vault Secret URL** field
4. Click **Add**

---

## Step 7 — Add Environment Variables to the Container

> **Note:** Secrets creation is complete. To use secrets inside the container, you must map them as environment variables.

1. Go to **Application** → **Containers** → **Edit and Deploy**
2. Click on the Container Image → **keyvault-demo-app** → **Environment Variables** → **+ Add**
3. Add the following variables:

| Name | Source | Value |
|---|---|---|
| `key1` | Reference a secret | `key1` |
| `key2` | Reference a secret | `key2` |

4. Click **Save** → **Create**

> **Note:** This step creates a new Revision. The old Revision will be decommissioned automatically.

---

## Step 8 — Test the Application

1. Go to **ACA** → **keyvault-demo-app** → **Overview**
2. Click on the **Application URL**
3. Verify the output:

```
Key1 --> ThisIsaACASecret
Key2 --> secretfromkeyvault
```










---

## 4. Authentication and Authorization

📖 Reference: [Microsoft Entra authentication for Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/authentication-entra)

Azure Container Apps has built-in authentication middleware (no code changes required). Two authentication flows are available:

| Flow | Use Case |
|------|----------|
| **Server-Directed** | Browser-based web applications |
| **Client-Directed** | Mobile backends and APIs |

### Lab: Server-Directed Flow (Microsoft Entra ID)

**Deploy the demo app:**

```bash
environment="my-containerapps-env"

az containerapp create \
  --name auth-demo-app \
  --resource-group $RESOURCE_GROUP \
  --environment $environment \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress external
```

**Enable authentication in the Portal:**

1. **Overview** — verify the app loads publicly
2. **Security > Authentication > Add identity provider > Microsoft**
3. Configure:
   - App registration: **Create new**
   - Tenant: **Current tenant — Single tenant**
   - Unauthenticated requests: **Require authentication**
   - Redirect: **HTTP 302 Found (recommended for websites)**
4. **Permissions tab > Add Permissions** — select all OpenID permissions: `email`, `offline_access`, `openid`, `profile`
5. **Update permissions > Add**

**Test authentication:**

Open a private browser tab and navigate to:

```
https://auth-demo-app.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us
```

You should be redirected to Microsoft login before accessing the app.

**Review the app registration:**

- **Portal > Microsoft Entra ID > Manage > App registrations > Owned applications > `auth-demo-app`**
- **Manage > Authentication** — review the Web Redirect URIs that were auto-configured

📖 Further reading: [App Service Authentication architecture](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization)

---

## 5. Logging and Observability

📖 Reference: [Azure Container Apps observability](https://learn.microsoft.com/en-us/azure/container-apps/observability)

Azure Container Apps provides layered observability across two log types and two scopes:

| | Console Logs | System Logs |
|--|--|--|
| **App-level** | Your app's stdout/stderr | Platform events for one app |
| **Environment-level** | N/A | Platform events across all apps |

---

### 5.1 Environment System Log Stream

Streams real-time infrastructure events (scheduling, scaling, networking) for all apps in the environment.

**CLI:**

```bash
# Live stream
az containerapp env logs show \
  --name $ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --follow

# Tail last 50 lines
az containerapp env logs show \
  --name $ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --tail 50
```

**Portal:** Container Apps Environments > `my-containerapps-env` > **Monitoring > Log stream**

> **Example system event:**
>
> ```json
> {
>   "Type": "Normal",
>   "ContainerAppName": "my-container-app",
>   "Msg": "Started container 'my-container-app'",
>   "Reason": "ContainerStarted"
> }
> ```

---

### 5.2 Container App Log Stream

Streams logs from a specific container app in real time.

**Console logs (app stdout/stderr):**

```bash
az containerapp logs show \
  --type console \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --follow
```

Portal: Container App > **Monitoring > Log stream > Console**

**System logs (platform events for this app):**

```bash
az containerapp logs show \
  --type system \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --follow
```

Portal: Container App > **Monitoring > Log stream > System**

---

### 5.3 Container Console (Interactive Shell)

Connect directly into a running container for debugging.

**CLI:**

```bash
az containerapp exec \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP
```

**Portal:** Container App > **Monitoring > Console > `/bin/sh` or `/bin/bash`**

**Common debugging commands:**

```bash
# Example 1: Inspect application files
cd /usr/share/nginx/html
cat index.html

# Example 2: Check secrets/env vars injected from Key Vault
printenv | grep -i "connection\|db\|sql"

# Example 3: Test database connectivity
curl -v $DB_HOST:5432

# Example 4: Verify DB migration state
psql $CONNECTION_STRING -c \
  "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 5;"

# Example 5: Test internal microservice connectivity
curl https://container-app-internal.internal.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us

# Example 6: Test outbound connectivity to a FHIR endpoint
curl -v \
  -H "Authorization: Bearer $FHIR_API_TOKEN" \
  https://myfhirserver.azurehealthcareapis.com/Patient
```

---

### 5.4 Metrics

📖 Reference: [Azure Container Apps metrics](https://learn.microsoft.com/en-us/azure/container-apps/metrics)

Container Apps exposes key metrics through Azure Monitor:

| Metric | Description |
|--------|-------------|
| CPU Usage | Raw CPU consumed |
| CPU Usage Percentage | CPU as % of allocated limit |
| Memory Percentage | Memory as % of allocated limit |
| Network In Bytes | Inbound network traffic |
| Resiliency Connection Timeouts | Failed connection attempts |

**View metric snapshots:**

Portal: Container App > **Overview > Monitoring section**

**Use Metrics Explorer:**

Portal: Container App > **Monitoring > Metrics** — add filters and dimensions

**Create alert rules:**

Portal: Container App > **Monitoring > Alerts > Create alert rule**

| Alert setting | Example value |
|---------------|---------------|
| Signal | CPU Usage Percentage |
| Threshold | > 50% |
| Alert type | Metric alert |

Two alert types are available:

- **Metric alerts** — triggered by Azure Monitor metric thresholds
- **Log alerts** — triggered by Log Analytics query results
