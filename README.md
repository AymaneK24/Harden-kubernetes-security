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
```

## Deploy frontend
``` bash
kubectl apply -f frontend/manifests/deployment.yaml

kubectl apply -f frontend/manifests/service.yaml
```

#### Notes:
variables environment for frontend are injected in the build time :
 -> npm start is a bad practice in dockerfile and means we can inject env vars in runtime which is baad!  

variables environment for backend are injected in runtime

browser communicates with both backend and frontend, it's not frontend that communicates with backend
