#!/bin/bash

echo "Deleting Kind cluster..."
kind delete cluster

echo "Stopping and removing local Docker registry..."
docker stop registry && docker rm registry

echo "Uninstalling cert-manager CRDs..."
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml

echo "Uninstalling KServe..."
kubectl delete -f https://github.com/kserve/kserve/releases/latest/download/kserve.yaml

echo "Stopping PostgreSQL..."
if [[ "$(uname -r)" == *"WSL"* ]]; then
    sudo service postgresql stop
else
    sudo systemctl stop postgresql
    sudo systemctl disable postgresql
fi

echo "Deleting Nginx deployment and service..."
kubectl delete deployment nginx
kubectl delete service nginx

echo "Cleanup completed!"