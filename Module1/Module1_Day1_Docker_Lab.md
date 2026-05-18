# Module 1 / Day 1 Lab: Containers Core Concepts

## Prerequisites

Before you begin, make sure you have the following:

**Azure Subscription:** Access to an Azure subscription with permission to create resources.

**Azure CLI:** Confirm by running az --version. If needed, install from the Azure CLI installation guide

- [How to install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)


**Azure Container Apps CLI Extension:** Install or update the Azure Container Apps extension, which provides the az containerapp commands:

az extension add --name containerapp --upgrade

(If you see errors about unrecognized commands, the extension may be missing or outdated.)

**Docker:** Install the Docker Desktop/command-line tool Confirm by running docker --version. Docker is required to build and test the container image locally.

- [How to install the Docker](https://docs.docker.com/desktop/)

**Kubectl CLI:** Kubernetes command-line tool.  

- [How to install the Kubectl CLI](https://kubernetes.io/docs/tasks/tools/)

**GIT:** Allows you to interact with the Git version control system by typing specific commands into a terminal

**Code Editor:** (Optional) Visual Studio Code or another editor for editing application files.

## Overview & References

- **Workshop Guide:** [Azure Container Apps Lab for Beginners](https://moaw.dev/workshop/?src=gh:yelghali/azure-container-apps-lab-beginners/main/docs/)

---

## Docker Demo Topics

1. Setup Azure Resources
2. Create a Java container
3. Create a .NET container
4. Create a Python container
5. Create a web/html container
6. Push an image to Azure Container Registry (ACR)
7. Push an image to DockerHub
8. Other Docker commands (e.g., bash into a running container)

---

## Section 1: Setup Azure Resources

### 1.1 Login and Provider Registration

```bash

# 1. Set the cloud to Azure Government
az cloud set --name AzureUSGovernment

# 2. Sign in to your Azure Government account
az login

# 3. (Optional) Verify the active cloud
az cloud list --output table
az cloud show
**Commercial Cloud:** az cloud set --name AzureCloud

# Add the Container Apps extension
az extension add --name containerapp --upgrade

# Register required Azure resource providers
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
```

### 1.2 Create a Resource Group

```bash
RESOURCE_GROUP="aca_resourcegroup13"
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

 ---

## Section 2: Build a Docker Image Locally

git clone https://github.com/cheruvu1/ACA_Workshop_Labs.git

# 2. Create a Java container

Goto the folder: Module1/Java-SprintBoot-App/spring-boot-web-service


## Quick test

```bash
mvn spring-boot:run

http://localhost:8080/ContainerApp

```


## Build and test 

```bash
mvn clean install
java -jar target/spring-boot-2-web-service-1.0.2-SNAPSHOT.jar
```

# Testing 
Send an HTTP GET request to '/ContainerApp' endpoint using any of the two methods

```bash
Browser or REST client
http://localhost:8080/ContainerApp

cURL
curl --request GET 'http://localhost:8080/ContainerApp'

```


## Review Dockerfile (Module1/Java-SprintBoot-App/spring-boot-web-service)

** x86 or Linux OS commands

```bash
docker build  -t spring-boot-web-service:1.0 .
docker images
docker run -p 8080:8080 spring-boot-web-service:1.0

```

**ARM (Apple Silicon / ARM-based PC/Mac):**

```bash
docker build --platform=linux/arm64 -t spring-boot-web-service:1.0-arm64 .
docker images
docker run -p 8080:8080 spring-boot-web-service:1.0-arm64

```

Then open your browser and navigate to: 


[http://localhost:8080/ContainerApp](http://localhost:8080/ContainerApp)

 

# Review Container-BluePrint (Module1/Images/Java-Dockerfile/Container-BluePrint.png)

# 3. Create a .NET container

```bash

Goto the folder: Module1/DotNet/ASP-Net-Core-WebApplication/ASP-Net-Core-WebApplication


docker build --platform=linux/arm64 -t dotnet-webapplication:1.0-arm64 .
docker images
docker run --user root -p 8080:8080 dotnet-webapplication:1.0-arm64
 
Then open your browser and navigate to: 

```

[http://localhost:8080/](http://localhost:8080/)



# 4. Create a Python container

```bash

cd Module1/PythonApp

docker build --platform=linux/arm64 -t python-application:1.0-arm64 .
docker images
docker run -p 5001:5000 python-application:1.0-arm64

Then open your browser and navigate to: 

```

[http://localhost:5001](http://localhost:5001)




### 5 Create the Web/HTML Application Content

# Folder: cd Module1/Web

Create a file named `index.html`:

```bash

html
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

### 5.1 Create a Dockerfile

# dockerfile

```bash

FROM nginx:alpine

# Copy the static HTML page to Nginx's default directory
COPY index.html /usr/share/nginx/html/index.html

```

### 5.2 Build the Docker Image

**Standard (x86/x64):**

```bash
docker build -t mycontainerapp:v1 .
```

**ARM (Apple Silicon / ARM-based PC/Mac):**

```bash
docker build --platform=linux/arm64 -t mycontainerapp:1.0-arm64 .
```

### 5.3 Run the Container Locally

```bash
# ARM build
docker run -d -p 8080:80 mycontainerapp:1.0-arm64
```

Then open your browser and navigate to: [http://localhost:8080](http://localhost:8080)

## Optional: Follow below steps to remove a running container

```bash

docker ps (Find the ContainerID)
docker stop 1d7ccca213b0
docker rm 1d7ccca213b0

```

---

## 6. Push the Image to Azure Container Registry

### 6.1 Log In to ACR

```bash
ACR_NAME=myacrlab16284
az acr login --name $ACR_NAME
```

### 6.2 Tag the Image with the ACR Repository Name

```bash
# Get the ACR login server URL
ACR_NAME=myacrlab17.azurecr.us

ACR_LOGIN_SERVER=$(az acr show -n $ACR_NAME --query "loginServer" -o tsv)



# Standard tag
docker tag mycontainerapp:v1 $ACR_LOGIN_SERVER/mycontainerapp:v1

# ARM tag
docker build --platform=linux/amd64 -t mycontainerapp:1.0-amd64 .

docker tag mycontainerapp:1.0-amd64 $ACR_LOGIN_SERVER/mycontainerapp:1.0-amd64

# Verify images
docker images
```

### 6.3 Push the Image to ACR

```bash

# Login to ACR
az login (if you already executed earlier, you can ignore)
az acr login --name $ACR_LOGIN_SERVER

# Standard push
docker push $ACR_LOGIN_SERVER/mycontainerapp:v1

# ARM push
 
docker push $ACR_LOGIN_SERVER/mycontainerapp:1.0-amd64

# Verify the image is in ACR
az acr repository list --name $ACR_NAME -o table
```

### 6.4 Verify in Azure Portal

Log in to the [Azure Portal](https://portal.azure.com) and navigate to your Container Registry to confirm the image was pushed successfully.


## 7. Push an image to DockerHub


Use this approach when pushing to a public container registry.

http://hub.docker.com



```bash
# 7.1 Build the image
docker build --platform=linux/amd64 -t mycontainerapp:1.0-amd64 .

# 7.2 Verify the image exists
docker images

# 7.3 Tag for DockerHub
docker tag mycontainerapp:1.0-amd64 cheruvu007/mycontainerapp:1.0-amd64

# 7.4 Log in to DockerHub
docker login
# Follow the device confirmation prompt, then open:

# https://login.docker.com/activate

# 7.5 Push to DockerHub
docker push cheruvu007/mycontainerapp:1.0-amd64
```

Log in to the [Docker Hub](https://hub.docker.com) and navigate to your Docker Hub Registry to confirm the image was pushed successfully.

Review Docker Official Images [Docker Images](https://hub.docker.com/search?badges=official)

Review Docker Hardened Images [Docker Hardened Images](https://hub.docker.com/search?badges=hardened)

Review DOD PlatformOne Iron Bank Images, Trusted by the DoD.  [Iron Bank Images](https://p1.dso.mil/iron-bank)




---


# 8. Other Docker commands (CLI Cheat Sheet)

# INSTALLATION

```bash

#Docker Desktop is available for Mac, Linux and Windows
https://docs.docker.com/desktop

#View example projects that use Docker
https://github.com/docker/awesome-compose

#Check out our docs for information on using Docker
https://docs.docker.com

```


## IMAGES
Docker images are a lightweight, standalone, executable package
of software that includes everything needed to run an application:
code, runtime, system tools, system libraries and settings.

```bash
#Build an Image from a Dockerfile
docker build -t <image_name> .

#Build an Image from a Dockerfile without the cache
docker build -t <image_name> . –no-cache

#List local images
docker images

#Delete an Image
docker rmi <image_name>

#Remove all unused images
docker image prune
```

## DOCKER HUB
Docker Hub is a service provided by Docker for finding and sharing
container images with your team. Learn more and find images
at https://hub.docker.com

```bash
#Login into Docker
docker login -u <username>

#Publish an image to Docker Hub
docker push <username>/<image_name>

#Search Hub for an image
docker search <image_name>

#Pull an image from a Docker Hub
docker pull <image_name>

```

## CONTAINERS

A container is a runtime instance of a docker image. A container
will always run the same, regardless of the infrastructure.
Containers isolate software from its environment and ensure
that it works uniformly despite differences for instance between
development and staging.

```bash
#Create and run a container from an image, with a custom name:
docker run --name <container_name> <image_name>

#Run a container with and publish a container’s port(s) to the host.
docker run -p <host_port>:<container_port> <image_name>

#Run a container in the background
docker run -d <image_name>

#Start or stop an existing container:
docker start|stop <container_name> (or <container-id>)

#Remove a stopped container:
docker rm <container_name>

#Open a shell inside a running container:
docker exec -it <container_name> sh

#Fetch and follow the logs of a container:
docker logs -f <container_name>

#To inspect a running container:
docker inspect <container_name> (or <container_id>)

#To list currently running containers:
docker ps

#List all docker containers (running and stopped):
docker ps --all

#View resource usage stats
docker container stats

```