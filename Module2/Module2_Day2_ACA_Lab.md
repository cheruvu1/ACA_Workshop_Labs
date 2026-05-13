# Module 2 / Day 2 Lab: Azure Container Apps

---

## Section 4: Deploy the Container to Azure Container Apps

### 4.1 Create the Container App

There are two ways to create an Azure Container App. Choose one option below.

**Option 1: Create via Azure CLI (using registry credentials)**

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

> **Note:** The registry password is stored as a secret (e.g., `myacrlab16284azurecrus-myacrlab16284`). Review it under **Security > Secrets** in the portal.

**Option 2: Create via Azure Portal**

Navigate to the [Azure Portal](https://portal.azure.com) and use the Container Apps creation wizard.

### 4.2 Verify the Deployment

```bash
az containerapp show \
  -n $APP_NAME \
  -g $RESOURCE_GROUP \
  --query "properties.configuration.ingress.fqdn" \
  -o tsv
```

> **Example output:** `my-container-app.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us`

### 4.3 Additional Deployments

Explore more Container Apps deployment patterns in the [workshop guide](https://moaw.dev/workshop/?src=gh:yelghali/azure-container-apps-lab-beginners/main/docs/#3-push-the-image-to-azure-container-registry).

---

## Section 5: Explore Image Deployment Strategies

### 5.1 Using Registry Credentials (Username/Password)

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

### 5.2 Using Managed Identity ⭐ (Recommended for Production)

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

### 5.3 Using a Public Registry (No Auth — e.g., DockerHub)

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

## Section 6: Explore Hosting Options (Ingress Settings)

Azure Container Apps supports three ingress modes:

| Mode | Accessibility | Use Case |
|------|--------------|----------|
| **External** | Public internet | Web apps, public HTTP APIs |
| **Internal** | Within the ACA environment / VNet only | Microservices, private backends |
| **None** | No endpoint | Background jobs, event-driven processing |

### 6.1 Create an App with External Ingress (Public)

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

### 6.2 Create an App with Internal Ingress

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

```bash
# Exec into the mi-container-app container
az containerapp exec \
  --name mi-container-app \
  --resource-group $RESOURCE_GROUP \
  --command "/bin/sh"

# Inside the container, test the internal endpoint
curl https://container-app-internal.internal.victoriousbush-05a7d3b0.usgovvirginia.azurecontainerapps.us
```

### 6.3 Create an App with No Ingress

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

## Section 7: Advanced Ingress — Traffic Splitting (Blue/Green & Canary Deployments)

**Blue-Green:** Route all traffic to v1 (blue), deploy v2 (green), then switch 100% at once.  
**Canary:** Gradually shift a small percentage of traffic to v2 while monitoring stability.

### 7.1 Build and Push Version 2

```bash
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

### 7.2 Enable Multiple Revisions Mode

To run both versions simultaneously, switch to multiple revision mode:

```bash
az containerapp revision set-mode \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --mode multiple
```

> In the portal: **Application > Revisions and Replicas > Choose Revision Mode**

### 7.3 Deploy the New Revision (v2)

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

### 7.4 Split Traffic Between Revisions

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

## Section 8: Advanced Networking — IP Restrictions

IP restrictions let you control which clients can reach your container app's public endpoint.

| Mode | Behavior |
|------|----------|
| **Allow** | Only listed IPs are permitted; all others are blocked |
| **Deny** | Listed IPs are blocked; all others are permitted |

> **Important:** You cannot mix Allow and Deny rules on the same app — choose one mode.

### 8.1 Add an IP Allow Rule

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

### 8.2 Test the IP Restriction

Access the app from a different network or device to confirm it is blocked.

### 8.3 Remove an IP Allow Rule

```bash
az containerapp ingress access-restriction remove \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --rule-name "AllowMyIP"
```

### 8.4 Add an IP Deny Rule

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

## Section 9: Replicas — Application Scaling (Availability)

> _Content coming soon — covers horizontal scaling via replica configuration._

---

## Section 10: Environment Variables

Review and manage environment variables in the portal:

**Portal path:** Container App > **Application > Containers > Environment Variables**

### Azure Key Vault Integration

> _Content coming soon — covers referencing Key Vault secrets as environment variables._
