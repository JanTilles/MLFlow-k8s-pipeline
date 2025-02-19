#!/bin/bash

echo "Updating package lists..."
sudo apt update -y && sudo apt upgrade -y

# Function to check if a package is installed
check_package() {
    dpkg -l | grep -q "$1"
    if [ $? -eq 0 ]; then
        echo "$1 is already installed."
    else
        echo "Installing $1..."
        sudo apt install -y "$1"
    fi
}

echo "Checking and installing required system dependencies..."
check_package python3
check_package python3-venv
check_package python3-pip
check_package docker.io
check_package docker-compose
check_package kubectl
check_package helm
check_package postgresql
check_package postgresql-contrib

# Ensure Docker is running
if ! sudo systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Check if Minikube is installed
if command -v minikube &> /dev/null; then
    echo "Minikube is already installed."
else
    echo "Installing Minikube..."
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/
fi

# Check if MLflow, Airflow, and Evidently AI are installed and upgrade if needed
pip_list=$(pip list)
for package in "mlflow" "apache-airflow" "evidently"; do
    if echo "$pip_list" | grep -q "$package"; then
        echo "$package is already installed, upgrading to latest version..."
        pip install --upgrade "$package"
    else
        echo "Installing $package..."
        pip install "$package"
    fi
done

echo "Starting Minikube..."
minikube start --driver=docker

# Check if Docker registry is running
if docker ps | grep -q "registry"; then
    echo "Local Docker registry is already running."
else
    echo "Setting up local Docker registry..."
    docker run -d -p 5000:5000 --restart=always --name registry registry:2
fi

echo "Configuring Kubernetes to use local registry..."
kubectl apply -f https://github.com/kserve/kserve/releases/latest/download/kserve.yaml

echo "Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo "Installation completed! You can now deploy the MLflow + Kubernetes pipeline."
