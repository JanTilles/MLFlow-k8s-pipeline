#!/bin/bash

echo "Updating package lists..."
sudo apt update -y && sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y python3 python3-pip docker.io docker-compose kubectl helm postgresql postgresql-contrib

echo "Installing Airflow..."
pip install apache-airflow

echo "Installing MLflow..."
pip install mlflow

echo "Installing Evidently AI for drift detection..."
pip install evidently

echo "Installing Kubernetes tools..."
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "Installing Minikube for local Kubernetes cluster..."
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

echo "Starting Minikube..."
minikube start --driver=docker

echo "Installing KServe..."
kubectl apply -f https://github.com/kserve/kserve/releases/latest/download/kserve.yaml

echo "Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo "Installation completed! You can now deploy the MLflow + Kubernetes pipeline."
