## Dynamic Provisioning 

cd AKSWorkshop/Lab/Module4/Persistence/Static-Provisioning


# Deploy the Storage Class and PVC to create the Storage Account & File Share
# Dynamically create the Azure Storage Account instead of manually creating it.

1. kubectl apply -f azure-file-sc.yaml 
   storageclass.storage.k8s.io/my-azurefile created

2. kubectl get storageclass   
   kubectl describe sc my-azurefile

3. kubectl apply -f azure-file-pvc.yaml
   persistentvolumeclaim/my-azurefile created

4. kubectl get pvc
5. Goto --> 
Azure Portal --> RG: MC_aksworkshopRG_aksworkshopcluster_usgovvirginia 
--> Storage Account --> fc72bf63a9f6e438daf27e4

6. File shares --> pod-file-share --> Browse --> Empty

7. For your Pod to get access to the File shares --> It need permission/access
   Security + networking --> Access Keys

8. Storage Account automatically create the secret for you,
  kubectl get secrets --> azure-storage-account-fc72bf63a9f6e438daf27e4-secret 
  kubectl describe secret azure-storage-account-fc72bf63a9f6e438daf27e4-secret

9. kubectl get secret azure-storage-account-fc72bf63a9f6e438daf27e4-secret -o yaml

10. kubectl apply -f app-pod.yaml
    kubectl get pods 
   kubectl get pv (Note: Persistent Volume Automatically created by Storage Class)
   pvc-ce158f4b-c44b-445a-915a-73be4bc15fdd 

11. kubectl exec pod/nginx-storageclass-pod -it -- /bin/sh
    # From inside the Pod shell:
    # ls /mnt/azure
    # echo "Hello from Azure File Share - Pod" > /mnt/azure/myfile.txt
    # ls /mnt/azure
    # cat /mnt/azure/myfile.txt
    # exit 

12. Go to --> Azure Portal --> File shares --> pod-file-share --> myfile.txt --> Edit --> See the content and Add text --> Hello from Azure Cloud Storage Account --> Pod File Share. 
   # From inside the Pod shell:
     Hello from Azure Cloud Storage Account --> Pod File Share. 

13. Create a 2nd Pod try to access the Storage Account
    kubectl apply -f app-2-pod.yaml 
    kubectl get pods 
    kubectl exec pod/nginx-storageclass-pod-2 -it -- /bin/sh
    # From inside the Pod shell:
    # ls /mnt/azure 
    # cat /mnt/azure/myfile.txt