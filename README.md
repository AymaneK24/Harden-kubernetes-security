# Harden-Kubernetes-security

![alt text](Images/image.png)

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



## Exposing the app on the browser

##### Create the infra 
``` bash
cd Infrastructure
terraform apply
```

``` bash

kubectl create namespace ingress-basic

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-basic \
    --set controller.replicaCount=2

# Label the cert-manager namespace to disable resource validation
kubectl label namespace ingress-basic cert-manager.io/disable-validation=true

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install CRDs with kubectl
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml

# Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager \
  --namespace ingress-basic \
  --version v1.7.1


```
### Create a CA cluster issuer
Expose/cluster-issuer.yaml

``` bash

kubectl apply -f cluster-issuer.yaml --namespace ingress-basic

```
### app in the cluster 


Rebuild frontend with new env var : domainename

``` bash

kubectl apply -f mongo/manifests/pvc.yaml -n ingress-basic

kubectl apply -f mongo/manifests/secret.yaml -n ingress-basic

kubectl apply -f mongo/manifests/configmap.yaml -n ingress-basic

kubectl apply -f mongo/manifests/statefulset.yaml -n ingress-basic

kubectl apply -f mongo/manifests/service.yaml -n ingress-basic

kubectl apply -f backend/manifests/deployment.yaml -n ingress-basic

kubectl apply -f backend/manifests/service.yaml -n ingress-basic

kubectl apply -f frontend/manifests/deployment.yaml -n ingress-basic

kubectl apply -f frontend/manifests/service.yaml -n ingress-basic


```



### create Ingress 

``` bash

kubectl apply -f ingress.yaml --namespace ingress-basic


kubectl patch service ingress-nginx-controller -n ingress-basic -p '{
   "metadata": {
     "annotations": {
       "service.beta.kubernetes.io/azure-load-balancer-health-probe": "{\"protocol\":\"Http\",\"port\":80,\"path\":\"/healthz\",\"intervalInSeconds\":5,\"numberOfProbes\":2}",
       "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path": "/healthz"
      }
    }
}'


```

