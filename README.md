# Harden-Kubernetes-security 

![alt text](Images/image.png)

in local how by this : older version of the commit that uses NodePort insetad of ClusterIP in manifests services backend and frontend 

## Deploy MongoDB Database 

``` bash
kubectl apply -f mongo/manifests/pvc.yaml 

kubectl apply -f mongo/manifests/secret.yaml 

kubectl apply -f mongo/manifests/configmap.yaml 

kubectl apply -f mongo/manifests/statefulset.yaml

kubectl apply -f mongo/manifests/service.yaml

```

## Deploy Backend
``` bash
kubectl apply -f backend/manifests/deployment.yaml 

kubectl apply -f backend/manifests/service.yaml 

## Deploy frontend
``` bash
kubectl apply -f frontend/manifests/deployment.yaml

kubectl apply -f frontend/manifests/service.yaml
```

#### Notes:
.env vars for frontend are injected in the build time :
 -> npm start is a bad practice in dockerfile and means we can inject env vars in runtime which is baad!  

.env vars for backend are injected in runtime

browser communicates with both backend and frontend, it's not frontend that communicates with backend





# Complete AKS Deployment Guide - Secure HTTPS Todo Application

This guide documents the complete deployment process for deploying a three-tier application (MongoDB, Backend, Frontend) on Azure Kubernetes Service (AKS) with secure HTTPS using Let's Encrypt.

---
![alt text](<WhatsApp Image 2025-11-15 at 17.50.47_460a3c40.jpg>)

##  Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Build and Push Docker Images](#build-and-push-docker-images)
4. [Deploy to Kubernetes](#deploy-to-kubernetes)
5. [Setup Ingress and SSL](#setup-ingress-and-ssl)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
- Azure CLI (`az`)
- Terraform
- kubectl
- Helm 3
- Docker
- A registered domain name (e.g., aymanekenbouch.online)

### Azure Setup
```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your-Subscription-ID"
```

---

## 1. Infrastructure Setup

### Deploy Azure Resources with Terraform

```bash
# Navigate to Infrastructure directory
cd Infrastructure

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration , type yes if you didn't use -auto-approve
terraform apply -auto-approve
```

**What this creates:**
- Resource Group: `integrated-project-rg`
- AKS Cluster: `integrated-project-aks`
- 1 node with VM size: Standard_B2s

### Connect to AKS Cluster

```bash
# Get AKS credentials - update the context to the  remote aks cluster
az aks get-credentials --resource-group integrated-project-rg --name integrated-project-aks --overwrite-existing

# Verify the connection
kubectl get nodes
```

## 2. Build and Push Docker Images

### Frontend Image

to use the new domaine name in the .env variable 

REACT_APP_BACKEND_URL="https://aymanekenbouch.online/api/tasks"

```bash
# locate in frontend root dir
cd frontend

# Build the image (update tag as needed)
docker build -t aymanekh24/todo-frontend:v3 .

# Tag the image 
docker tag aymanekh24/todo-frontend:v3 aymanekh24/todo-frontend:v3

# Push to Docker Hub
docker push aymanekh24/todo-frontend:v3

# Return to root
cd ..
```


## 3. Deploy to Kubernetes

### Create Namespace

```bash
# Create app namespace
kubectl create namespace app
```

### Deploy MongoDB

```bash
# Apply MongoDB manifests in order
kubectl apply -f mongo/manifests/pvc.yaml -n app
kubectl apply -f mongo/manifests/secret.yaml -n app
kubectl apply -f mongo/manifests/configmap.yaml -n app
kubectl apply -f mongo/manifests/statefulset.yaml -n app
kubectl apply -f mongo/manifests/service.yaml -n app

# Wait for MongoDB to be ready (up to 5 minutes)
kubectl wait --for=condition=ready pod -l app=mongodb -n app --timeout=300s


# Verify MongoDB pod is running
kubectl get pods -n app
```

### Deploy Backend

```bash
# Apply backend manifests
kubectl apply -f backend/manifests/deployment.yaml -n app
kubectl apply -f backend/manifests/service.yaml -n app

# Verify backend is running
kubectl get pods -n app

# Check backend logs, you should see Connected to Database before continuing if you don't see it debug !!!
kubectl logs -l app=backend -n app 

```

### Deploy Frontend

```bash
# Apply frontend manifests
kubectl apply -f frontend/manifests/deployment.yaml -n app
kubectl apply -f frontend/manifests/service.yaml -n app

# Wait for frontend to be ready
kubectl wait --for=condition=ready pod -l app=frontend -n app 


# Verify frontend is running
kubectl get pods -n app -l app=frontend

# Check frontend logs are good
kubectl logs -l app=frontend -n app
```

### Verify All Services

```bash
# Check all pods
kubectl get pods -n app

# Check all services
kubectl get services -n app

# Check service endpoints
kubectl get endpoints -n app
```

---

## 4. Setup Ingress and SSL

### Install NGINX Ingress Controller

```bash
# Add ingress-nginx Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update


```

With azure aks managed cluster an azure load balancer is created with a public ip address you may want to use it if you don't want to waste the ip public 
and that can be done with this : 


```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace app \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz" \
  --set controller.service.externalTrafficPolicy=Local

# Wait for ingress controller
kubectl get pods -n app -l app.kubernetes.io/name=ingress-nginx --watch


# Verify ingress controller service
kubectl get svc ingress-nginx-controller -n app

#Verify the annotation was applied
kubectl get svc ingress-nginx-controller -n app -o jsonpath='{.metadata.annotations}'
```
If not using a managed cluster (the load balancer was not created) or even if it was managaged and you wanted to use the ip public that's going to be created by kubernetes ingress-nginx-controller
do this : 

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace app \
    --set controller.replicaCount=2

```



### Install Cert-Manager

```bash
# Install cert-manager CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.1/cert-manager.crds.yaml

# Add Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace app \
  --version v1.19.1

# Verify cert-manager pods
kubectl get pods -n app -l app.kubernetes.io/instance=cert-manager
```


All cert-manager pods should be `Running`.

### Configure DNS

**CRITICAL STEP:** Before proceeding, configure your domain DNS , Create an A record ( in azure DNS Hosted Zone or Public domaine provider):

- Verify DNS propagation:
**Wait 1-3 minutes for DNS to propagate before continuing.**
```bash
nslookup aymanekenbouch.online
#it should show the ip it's mapped to then you can continue
```

### Create ClusterIssuer (Production Let's Encrypt)

```bash
# Navigate to Expose directory
cd Expose

# Apply ClusterIssuer (uses Let's Encrypt Production)
kubectl apply -f cluster-issuer.yaml -n app

# Verify ClusterIssuer is ready
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod
```

### Create Ingress with TLS

```bash
# Apply ingress configuration
kubectl apply -f ingress.yaml -n app

# Verify ingress was created
kubectl get ingress -n app

# if the app is not accessible through browser ( only if using managed cluster which creates an alb)
kubectl patch service ingress-nginx-controller -n ingress-basic -p '{
   "metadata": {
     "annotations": {
       "service.beta.kubernetes.io/azure-load-balancer-health-probe": "{\"protocol\":\"Http\",\"port\":80,\"path\":\"/healthz\",\"intervalInSeconds\":5,\"numberOfProbes\":2}",
       "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path": "/healthz"
      }
    }
}'

```

### Monitor Certificate Issuance
#### You should wait and wait 

```bash
# Watch certificate status (this takes 2-5 minutes) 
kubectl get certificate -n app --watch


# Check certificate details
kubectl describe certificate tls-secret -n app

# Check certificate request
kubectl get certificaterequest -n app

# Check if there are any challenges
kubectl get challenges -n app

# If challenges exist, describe them
kubectl describe challenges -n app
```

**Expected flow:**
1. Certificate status: `READY = False` (initially)
2. Challenge created and validated
3. Certificate status: `READY = True` (after 2-5 minutes)

---

## 5. Verification

### Check All Resources

```bash
# View all resources in namespace
kubectl get all -n app

# Check certificate
kubectl get certificate -n app

# Check secret (contains the TLS certificate)
kubectl get secret tls-secret -n app

# Check ingress details
kubectl describe ingress app-ingress -n app
```

### Test Application Access

```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://aymanekenbouch.online

# Test HTTPS
curl -I https://aymanekenbouch.online

# also verify the NSG in AZURE it should allow inbound and outbound from the internet through http port 80 and https port 443
```



### Access Application in Browser

1. Open browser 
2. Navigate to: `https://aymanekenbouch.online`
3. Verify:
   -  Green padlock/secure indicator
   -  No warnings
   -  Certificate issued by "Let's Encrypt"
   -  Application loads successfully

If there was a warning check certificate ```READY``` and certificateRequest ```READY```, IF IT IS , go to another browser cause it's probably a cache issue beacuse you did'nt wait till the certificateRequest is ```READY```.
- at this point, just go and clear the cache of the browser look how to it .


## 6. Troubleshooting

### Certificate Not Issuing

```bash
# Check certificate status
kubectl describe certificate tls-secret -n app

# Check challenges
kubectl get challenges -n app
kubectl describe challenges -n app

# Check cert-manager logs
kubectl logs -n app -l app=cert-manager --tail=100

# Common issue: Port 80 blocked
curl -I http://aymanekenbouch.online
# Should NOT timeout
```

### Fix: If Port 80 is Blocked

```bash
# List Network Security Groups
az network nsg list \
  --resource-group MC_integrated-project-rg_integrated-project-aks_eastus \
  --query "[].name" -o tsv

# Add rule to allow HTTP (if missing)
# Add rule to allow HTTPS (if missing) in Azure or through Console

```

### Certificate Failed - Retry
- and wait plase! (go scroll after below and try in new browser (i recommend it))

```bash
# Delete failed certificate
kubectl delete certificate tls-secret -n app

# Delete secret if exists
kubectl delete secret tls-secret -n app

# Delete and reapply ingress
kubectl delete ingress app-ingress -n app
kubectl apply -f ingress.yaml -n app

# Watch new certificate creation
kubectl get certificate -n app --watch
```

### Port Forward for Local Testing
- to confirm that the app logic metier is good
```bash
# Test backend directly
kubectl port-forward -n app svc/backend-service 3500:3500
# In browser: http://localhost:3500 

# Test frontend directly
kubectl port-forward -n app svc/frontend-service 8080:8080
# In browser: http://localhost:8080

```

### Verify Service Endpoints

```bash
# Check if services have endpoints
kubectl get endpoints -n app

# Describe service
kubectl describe svc backend-service -n app
kubectl describe svc frontend-service -n app
```

---

## 7. Clean Up (Optional) 

### Delete Kubernetes Resources and retry again 

```bash
# Delete all resources in namespace
kubectl delete namespace app 

# This removes:
# - All pods
# - All services
# - All ingress
# - All certificates
# - Ingress controller
# - Cert-manager
```

## 8. Delete Infra for cost saving 

```bash
# Navigate to Infrastructure directory
cd Infrastructure

# Destroy all Azure resources
terraform destroy -auto-approve
```

## 📊 Architecture Overview

```
Internet
    ↓
Azure Load Balancer (51.8.39.6)
    ↓
NGINX Ingress Controller
    ↓
    ├─→ /api → Backend Service → Backend Pods → MongoDB
    └─→ /    → Frontend Service → Frontend Pods
```

---

## ✅ Success Checklist

- ✅ Terraform infrastructure deployed
- ✅ AKS cluster accessible
- ✅ Docker images built and pushed
- ✅ MongoDB running and ready
- ✅ Backend deployed with endpoints
- ✅ Frontend deployed with endpoints
- ✅ Ingress controller has external IP
- ✅ DNS configured and propagated
- ✅ Cert-manager installed
- ✅ ClusterIssuer created
- ✅ Ingress with TLS configured
- ✅ Certificate issued (READY = True)
- ✅ HTTPS working with valid certificate
- ✅ Application accessible via domain

---

##  Security Notes

1. **SSL Certificate:** Using Let's Encrypt Production (trusted by all browsers)
2. **Certificate Renewal:** Automatic renewal by cert-manager (90 days validity)
3. **HTTPS Redirect:** All HTTP traffic redirected to HTTPS
4. **Secrets:** MongoDB credentials stored in Kubernetes secrets
5. **Network:** Azure NSG configured to allow ports 80 and 443

---

##  Useful Commands Reference

```bash
# View all resources
kubectl get all -n app

# Get pod logs
kubectl logs <pod-name> -n app --tail=100 -f

# Describe resource
kubectl describe <resource-type> <name> -n app

# Execute into pod
kubectl exec -it <pod-name> -n app -- /bin/bash

# Watch resources
kubectl get pods -n app --watch

# Get external IP
kubectl get svc ingress-nginx-controller -n app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Check certificate
kubectl get certificate -n app
kubectl describe certificate tls-secret -n app

# View ingress
kubectl get ingress -n app
kubectl describe ingress app-ingress -n app
```

---

