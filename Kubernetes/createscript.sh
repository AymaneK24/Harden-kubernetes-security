#!/bin/bash
kubectl apply -f volume.yml
kubectl apply -f secret.yml
kubectl apply -f deployment.yml
kubectl apply -f services.yml

