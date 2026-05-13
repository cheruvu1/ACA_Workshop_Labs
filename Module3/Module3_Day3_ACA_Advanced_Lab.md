# Module 3 / Day 3 Lab: Azure Container Apps — Advanced Topics

---

## Section 1: Bring Your Own Virtual Network (VNET)

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

3. Go to **Resource Groups > Container Apps Environment > VNetDemo-managedEnvironment** and copy the static IP (e.g., `10.0.2.68`)

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

## Section 2: Secrets Management

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
  --image kamalrathnayake/secretsdemo:latest \
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

7. Test the app URL again — secrets should now be visible
8. **Monitoring > Console > run `printenv`** — review `KEY1` and `KEY2`

**Optional cleanup:**

```bash
az group delete --resource-group $RESOURCE_GROUP --yes
```

---

## Section 3: Authentication and Authorization

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

## Section 4: Logging and Observability

📖 Reference: [Azure Container Apps observability](https://learn.microsoft.com/en-us/azure/container-apps/observability)

Azure Container Apps provides layered observability across two log types and two scopes:

| | Console Logs | System Logs |
|--|--|--|
| **App-level** | Your app's stdout/stderr | Platform events for one app |
| **Environment-level** | N/A | Platform events across all apps |

---

### 4.1 Environment System Log Stream

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
> ```json
> {
>   "Type": "Normal",
>   "ContainerAppName": "my-container-app",
>   "Msg": "Started container 'my-container-app'",
>   "Reason": "ContainerStarted"
> }
> ```

---

### 4.2 Container App Log Stream

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

### 4.3 Container Console (Interactive Shell)

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

### 4.4 Metrics

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
