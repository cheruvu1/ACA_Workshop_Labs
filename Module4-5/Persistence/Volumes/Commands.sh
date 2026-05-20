



1. kubectl get nodes 
2. kubectl debug node/aks-agentpool-31982318-vmss000001 -it --image=alpine
or
kubectl debug node/aks-agentpool-31982318-vmss000001 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
3. mkdir /mydata
4. Create a Pod with Volume path
kubectl get pods -n volume
5. kubectl describe pod employee-producer-pod -n volume
kubectl exec -it employee-producer-pod -n volume bash
touch newfile.txt
echo "Hi From AKS training team" > newfile.txt
df -h (/data folder mounted)


