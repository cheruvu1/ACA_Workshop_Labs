# Module 1 / Day 1 Lab: Containers Core Concepts

## Overview & References

- **Lab Script:** [AKS Workshop — cloudshell.sh](https://github.com/cheruvu1/AKSWorkshop/blob/main/Lab/cloudshell.sh)
- **Workshop Guide:** [Azure Container Apps Lab for Beginners](https://moaw.dev/workshop/?src=gh:yelghali/azure-container-apps-lab-beginners/main/docs/)

---

## Docker Demo Topics

1. Create a Java container
2. Create a .NET container
3. Create a Python container
4. Push an image to DockerHub
5. Other Docker commands (e.g., bash into a running container)

---

## Section 1: Setup Azure Resources

### 1.1 Login and Provider Registration

```bash
# Add the Container Apps extension
az extension add --name containerapp --upgrade

# Log in to Azure CLI (opens a browser for authentication)
az login

# Register required Azure resource providers
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
```

### 1.2 Create a Resource Group

```bash
RESOURCE_GROUP="aca_resourcegroup"
LOCATION="USGovVirginia"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 1.3 Create an Azure Container Registry (ACR)

```bash
# $RANDOM appends a random number to ensure a unique ACR name
ACR_NAME="myacrlab$RANDOM"

az acr create \
  --name $ACR_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Basic
```

> **Example ACR name created:** `myacrlab16284.azurecr.us`

### 1.4 Create an Azure Container Apps Environment

```bash
ENV_NAME="my-containerapps-env"

az containerapp env create \
  --name $ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
```

---

## Section 2: Build a Docker Image Locally

### 2.1 Create the Application Content

Create a file named `index.html`:

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Azure Container Apps - Demo</title>
  </head>
  <body>
    <h1>Hello from Azure Container Apps!</h1>
    <p>This is a sample app running in Azure Container Apps.</p>
  </body>
</html>
```

### 2.2 Create a Dockerfile

```dockerfile
FROM nginx:alpine

# Copy the static HTML page to Nginx's default directory
COPY index.html /usr/share/nginx/html/index.html
```

### 2.3 Build the Docker Image

**Standard (x86/x64):**

```bash
docker build -t mycontainerapp:v1 .
```

**ARM (Apple Silicon / ARM-based PC/Mac):**

```bash
docker build --platform=linux/amd64 -t mycontainerapp:1.0-amd64 .
```

### 2.4 Run the Container Locally

```bash
# ARM build
docker run -d -p 8080:80 mycontainerapp:1.0-amd64
```

Then open your browser and navigate to: [http://localhost:8080](http://localhost:8080)

---

## Section 3: Push the Image to Azure Container Registry

### 3.1 Log In to ACR

```bash
az acr login --name $ACR_NAME
```

### 3.2 Tag the Image with the ACR Repository Name

```bash
# Get the ACR login server URL
ACR_LOGIN_SERVER=$(az acr show -n $ACR_NAME --query "loginServer" -o tsv)

# Standard tag
docker tag mycontainerapp:v1 $ACR_LOGIN_SERVER/mycontainerapp:v1

# ARM tag
docker tag mycontainerapp:1.0-amd64 $ACR_LOGIN_SERVER/mycontainerapp:1.0-amd64

# Verify images
docker images
```

### 3.3 Push the Image to ACR

```bash
# Standard push
docker push $ACR_LOGIN_SERVER/mycontainerapp:v1

# ARM push
docker push $ACR_LOGIN_SERVER/mycontainerapp:1.0-amd64

# Verify the image is in ACR
az acr repository list --name $ACR_NAME -o table
```

### 3.4 Verify in Azure Portal

Log in to the [Azure Portal](https://portal.azure.us) and navigate to your Container Registry to confirm the image was pushed successfully.
