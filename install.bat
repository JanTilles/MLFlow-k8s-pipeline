@echo off
echo Updating package lists...
winget upgrade --all

echo Installing required dependencies...
winget install -e --id Python.Python.3.9
winget install -e --id Docker.DockerDesktop
winget install -e --id Kubernetes.kubectl
winget install -e --id Helm.Helm
winget install -e --id PostgreSQL.PostgreSQL

echo Installing Python packages...
pip install mlflow apache-airflow evidently

echo Starting Docker Desktop (ensure it is installed and running)...
start /B "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
timeout /t 10

echo Installing Minikube...
winget install -e --id Kubernetes.Minikube

echo Starting Minikube...
minikube start --driver=docker

echo Installing KServe...
kubectl apply -f https://github.com/kserve/kserve/releases/latest/download/kserve.yaml

echo Setting up PostgreSQL...
net start postgresql

echo Installation completed! You can now deploy the MLflow + Kubernetes pipeline.
pause
