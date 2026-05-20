
## AKS Tools

## 1. Create AKS Cluster

Install AKS Cluster using the Azure Portal
For future reference to install via CLI refer ClusterSetupGuide.pdf

## 2. Install necessary CLI tools AZ CLI / Kubectl / HELM

1) AZ CLI 
2) kubectl 
3) HELM:

   ## From Chocolatey (Windows)

    choco install kubernetes-helm
    helm version

   ## Linux Commands

    curl -fsSL -o get_helm.sh  <https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3>
    chmod 700 get_helm.sh
    ./get_helm.sh

## 3. Connect to the AKS cluster using the CLI tools

az account set --subscription <subscription ID>

az aks get-credentials --resource-group <Resource Group> --name <Cluster Name>

