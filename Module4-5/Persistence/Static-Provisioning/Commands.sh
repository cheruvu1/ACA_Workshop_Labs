# CSI File Drivers: https://learn.microsoft.com/en-us/azure/aks/azure-files-csi
# src: https://docs.microsoft.com/en-us/azure/aks/azure-files-volume

## Static Provisioning:



Note: This Lab assume that you already created an AKS Cluster

cd AKSWorkshop/Lab/Module4/Persistence/Static-Provisioning

1. Go to --> Azure Portal --> Resource Groups --> Capture the Resource Group Name for your MC AKS cluster
MC_aksworkshopRG_aksworkshopcluster_usgovvirginia
2. Go to --> Azure Portal --> Storage Account -- > Create a new Storage Account
Name: staticstorageaccount
RG: MC_aksworkshopRG_aksworkshopcluster_usgovvirginia
Select all the default sections and click on Review + Create

3. Go to --> Storage Account --> staticstorageaccount

Expand Data storage --> File Shares --> + File Share --> static-file-share
click on Review + Create
click on Create

4. Security + Networking --> Access Keys --> Capture  
 

 
5. kubectl create secret generic azure-secret 
--from-literal=azurestorageaccountname=staticstorageaccount  
--from-literal=azurestorageaccountkey=Replace with your key
 

kubectl get secrets
Note: Make sure azure-secret created successfully

6. cd AKSWorkshop/Lab/Module4/Persistence/Static-Provisioning
kubectl apply -f azure-file-pv.yaml
kubectl get pv

7.
kubectl apply -f azure-file-pvc.yaml 
    persistentvolumeclaim/azurefile created
kubectl get pvc
Note: Status: Bound
Volume: azurefile   


kubectl pv
Note: Status: Bound
CLAIM set to default/azurefile


8. 
kubectl apply -f app-pod.yaml 
kubectl get pods
kubectl describe pod mypod 
Note: 
Mounts:
      /mnt/azure from azure (rw)

9. kubectl exec pod/mypod -it -- /bin/sh
    # From inside the Pod shell:
    # ls /mnt/azure
    # echo "Hello from Azure File Share-Static-Provisioning sharing - Pod" > /mnt/azure/StaticShare.txt
    # ls /mnt/azure
    # cat /mnt/azure/StaticShare.txt

10. Azure Protal --> Data storage --> 
File Shares --> + File Share --> static-file-share --> Browse 
You will see the StaticShare.txt file created by the Pod.

11. Click on ... (3 dots next to the StaticShare.txt) 
Edit --> Hello from Azure Portal Storage Account --> Save 

12. kubectl exec pod/mypod -it -- /bin/sh
# cat /mnt/azure/StaticShare.txt


1. Go to --> Azure Portal --> Storage Account -- > Create a new Storage Account
Name: staticstorageaccount
RG: MC_aksbyexample_aksbyexample_usgovarizona

2. Go to --> Storage Account --> staticstorageaccount

Data storage --> File Shares --> + File Share --> static-file-share
3. Security + Networking --> Access Keys --> Capture 
 
4. kubectl create secret generic azure-secret 
--from-literal=azurestorageaccountname=staticstorageaccount  
--from-literal=azurestorageaccountkey= Replace with your key
5. kubectl get secrets 
6. kubectl apply -f azure-file-pv.yaml
7. kubectl get pv 
8. kubectl apply -f azure-file-pvc.yaml 
   persistentvolumeclaim/azurefile created
9. kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
azurefile      Bound    azurefile                                  5Gi        RWX                           15s
my-azurefile   Bound    pvc-                                       5Gi        RWX            my-azurefile   99m
10. kubectl apply -f app-pod.yaml 
11. kubectl get pods
12. kubectl describe pod mypod 
    Mounts:
      /mnt/azure from azure (rw)
13. kubectl exec pod/mypod -it -- /bin/sh
    # From inside the Pod shell:
    # ls /mnt/azure
    # echo "Hello from Azure File Share-Static-Provisioning sharing" > /mnt/azure/StaticShare.txt
    # ls /mnt/azure
    # cat /mnt/azure/StaticShare.txt
14. Azure Protal --> Data storage --> File Shares --> + File Share --> static-file-share
Edit --> Hello from Azure Portal Storage Account --> Save 
15. kubectl exec pod/mypod -it -- /bin/sh
# cat /mnt/azure/StaticShare.txt

