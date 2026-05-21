

## Getting started with Gateway API

https://gateway-api.sigs.k8s.io/guides/getting-started/introduction/

# Kubernetes Gateway API 

# Concepts Overview
Gateway API has three core resource types, each typically owned by a different role:

# 1. GatewayClass

```bash
Owned By: Cluster Admin
Purpose: Defines which controller handles Gateways

```
# 2. Gateway

```bash
Owned By: Cluster Operator
Purpose: Entry point — ports, protocols, listeners

```

# 3. HTTPRoute

```bash

Owned By: Developer
Purpose: Routing rules — paths, hostnames, backends

# HTTP routing Flow

```

# Step 1 — Install the Gateway API CRDs
# The standard release channel includes GA and beta resources (GatewayClass, Gateway, HTTPRoute, ReferenceGrant)

```bash

kubectl apply --server-side -f \
  https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml



```

Verify the CRDs are installed:

```bash
kubectl get crds | grep gateway
# Expected output:
# gateways.gateway.networking.k8s.io
# gatewayclasses.gateway.networking.k8s.io
# httproutes.gateway.networking.k8s.io
# referencegrants.gateway.networking.k8s.io


```

# Step 2 — Install a Gateway Controller
# You need a controller implementation. We'll use NGINX Gateway Fabric (straightforward for local testing). Choose one based on your environment:

```bash
# Install via Helm
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --set service.type=NodePort  # use LoadBalancer on cloud clusters
 



```

## Popular GatwayAPI providers

```bash

 Option A — NGINX Gateway Fabric (recommended for local/general use)
 Option B — Envoy Gateway (CNCF project)
 Option C — kind cluster with Envoy Gateway (full local setup)

 ```

# Option A — NGINX Gateway Fabric (recommended for local/general use)

You need a controller implementation. We'll use NGINX Gateway Fabric (straightforward for local testing). Choose one based on your environment:

```bash
# Install via Helm
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --set service.type=LoadBalancer  # use LoadBalancer on cloud clusters # use NodePort for on-prem

```

# If you want to switch between LoadBalancer vs NodePort 

```bash
helm upgrade ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --set service.type=LoadBalancer
```




Verify the controller pod is running:

```bash
kubectl get pods -n nginx-gateway   # or envoy-gateway-system

```


3 Step 3 — Deploy the Hello World Application
Create your backend app and service:

```bash

# hello-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: hashicorp/http-echo:latest
        args:
          - "-text=Hello from Kubernetes Gateway API!"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world-svc
  namespace: default
spec:
  selector:
    app: hello-world
  ports:
  - port: 80
    targetPort: 5678
  type: ClusterIP


kubectl apply -f hello-app.yaml
kubectl get pods   # wait until Running


```

# Step 4 — Create the GatewayClass
The GatewayClass tells Kubernetes which controller to use. The controllerName must match your installed controller:

```bash

# gatewayclass.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx  # or "eg" for Envoy Gateway
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
  # For Envoy Gateway use: gateway.envoyproxy.io/gatewayclass-controller


----
kubectl apply -f gatewayclass.yaml
kubectl get gatewayclass
# NAME    CONTROLLER                                      ACCEPTED
# nginx   gateway.nginx.org/nginx-gateway-controller     True


```

# Step 5 — Create the Gateway
The Gateway defines the listener — the entry point for traffic:

```bash

# gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: hello-gateway
  namespace: default
spec:
  gatewayClassName: nginx   # must match GatewayClass name above
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same  # only allow HTTPRoutes from this namespace

----

kubectl apply -f gateway.yaml

# Wait for it to be ready
kubectl get gateway hello-gateway
# NAME              CLASS   ADDRESS        PROGRAMMED   AGE
# hello-gateway     nginx   203.0.113.10   True         30s
 

```

# Review the Service and Gateway NGINX Loadbalancer IP
kubectl get service

```bash
#NAME                  TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
#hello-gateway-nginx   LoadBalancer   10.0.224.15   20.158.245.79   80:30173/TCP   27m
#hello-world-svc       ClusterIP      10.0.68.93    <none>          80/TCP         28m
#kubernetes            ClusterIP      10.0.0.1      <none>          443/TCP        9h
```


# Step 6 — Create the HTTPRoute
The HTTPRoute defines the actual routing rules — which paths/hostnames go to which services:

```bash
# httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: hello-route
  namespace: default
spec:
  parentRefs:
  - name: hello-gateway   # binds to our Gateway
  hostnames:
  - "hello.example.com"   # optional: remove to match all hostnames
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /hello
    backendRefs:
    - name: hello-world-svc
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: hello-world-svc
      port: 80

kubectl apply -f httproute.yaml

kubectl get httproute
# NAME          HOSTNAMES              AGE
# hello-route   ["hello.example.com"]  10s




```

# Step 7 — Test It
Get the Gateway's external address:

```bash

export GW_IP=$(kubectl get gateway hello-gateway \
  -o jsonpath='{.status.addresses[0].value}')
echo $GW_IP


```

# Test your routes:

```bash

# Test root path
curl http://$GW_IP/
# Hello from Kubernetes Gateway API!

# Test /hello path
curl http://$GW_IP/hello
# Hello from Kubernetes Gateway API!

# If using hostname matching, set the Host header:

curl -H "Host: hello.example.com" http://$GW_IP/hello

# Hello from Kubernetes Gateway API!

# Review httproute.yaml file 
# / path will also route to hello-world-svc service 
curl -H "Host: hello.example.com" http://$GW_IP/


```

# Step 8 - Add Path-Based Routing for Two Services
A common next step — routing /v1 and /v2 to different backends:

```bash

rules:
- matches:
  - path:
      type: PathPrefix
      value: /v1
  backendRefs:
  - name: hello-v1-svc
    port: 80
- matches:
  - path:
      type: PathPrefix
      value: /v2
  backendRefs:
  - name: hello-v2-svc
    port: 80



```
# GatewayAPI Reference :

 
# Check controller acceptance

kubectl get gatewayclassCheck 

# Listener status

kubectl get gateway

# Check route attachment
kubectl get httproute

# Debug routing issues
kubectl describe httproute hello-route

 



