# Module 3 / Day 3 Lab: Azure Container Apps — Advanced Topics

---

## Azure Container Apps Demo Topics

1. Bring Your Own Virtual Network (VNET)
2. Secrets Management
3. Azure Key Vault Integration
4. Authentication and Authorization
5. Logging and Observability

---

## 1. Bring Your Own Virtual Network (VNET)

### Overview

By default, Azure Container Apps runs in a managed network. This section walks through connecting your Container App to your own Virtual Network for private networking scenarios.

### Step 1: Create a Virtual Network

In the Azure Portal, create a VNet with the following settings:

| Setting | Value |
|---------|-------|
| Resource Group | `aca_resourcegroup` |
| Name | `container-apps-vnet` |
| Subnet 1 | `vm-subnet` — for the test Virtual Machine |
| Subnet 2 | `infra-subnet` — for the Container App infrastructure |

### Step 2: Create a Container App with VNet Integration

In the portal, create a new Container App with these settings:

| Setting | Value |
|---------|-------|
| Name | `vnet-demo-aca` |
| Environment (new) | `VNetDemo-managedEnvironment` |
| Networking > Own VNet | Yes |
| VNet | `container-apps-vnet` |
| Subnet | `infra-subnet` |
| Endpoint type | Internal load balancer |

After creation:

1. Enable Ingress on the app
2. Go to the **Overview** page and note the internal application URL:

```
https://vnet-demo-aca.internal.agreeablebay-776576db.usgovvirginia.azurecontainerapps.us
```

1. Go to **Resource Groups > Container Apps Environment > VNetDemo-managedEnvironment** and copy the static IP (e.g., `10.0.2.68`)

### Step 3: Create a Test VM in the Same VNet

To test private connectivity, deploy a VM in the same VNet:

| Setting | Value |
|---------|-------|
| Image | Windows 11 Pro, version 25H2 - Gen2 |
| Name | `windows-10-vm` |
| Username | `azureuser` |
| Networking > VNet | `container-apps-vnet` |
| Networking > Subnet | `vm-subnet` |

After the VM is created, RDP into it and paste the internal ingress URL into the browser to verify connectivity.

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
ACR_USER="myacrlab16284"
ACR_PASS="7YWoBJ6E0RBllgDCK2yl5F81Rrmro5xsj5tCQqUO0m7asCCRX0zaJQQJ99CEAAhseKSEqg7NAAACAZCRIOB2"
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
