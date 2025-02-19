#!/bin/bash

echo "Updating package lists..."
sudo apt update -y && sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y python3 python3-pip docker.io docker-compose kubectl helm postgresql postgresql-contrib

echo "Installing Airflow (latest version)..."
pip install apache-airflow

echo "Installing MLflow (latest version)..."
pip install mlflow

echo "Installing Evidently AI for drift detection (latest version)..."
pip install evidently

echo "Installing Kubernetes tools..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "Installing Minikube (latest stable version)..."
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

echo "Starting Minikube..."
minikube start --driver=docker

echo "Setting up local Docker registry..."
docker run -d -p 5000:5000 --restart=always --name registry registry:2

echo "Configuring Kubernetes to use local registry..."
kubectl apply -f https://github.com/kserve/kserve/releases/latest/download/kserve.yaml

echo "Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo "Installation completed! You can now deploy the MLflow + Kubernetes pipeline."
