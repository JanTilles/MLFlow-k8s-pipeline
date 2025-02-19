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
check_package helm
check_package postgresql
check_package postgresql-contrib

# Ensure user is in Docker group to avoid sudo requirement
if groups $USER | grep &>/dev/null "\bdocker\b"; then
    echo "User $USER is already in the docker group."
else
    echo "Adding $USER to the docker group..."
    sudo usermod -aG docker $USER
    echo "Please restart WSL with: exit, wsl --shutdown, wsl"
    exit 1  # Stop execution since user needs to restart WSL
fi

# Ensure Docker is running
if ! sudo systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    sudo dockerd --iptables=false --storage-driver=overlay2 &
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

# Install kubectl manually if not found
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
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

# Install cert-manager before KServe
echo "Installing cert-manager CRDs..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml

# Verify cert-manager installation
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Established crd/certificates.cert-manager.io --timeout=120s

# Install KServe
echo "Applying KServe..."
kubectl apply -f https://github.com/kserve/kserve/releases/latest/download/kserve.yaml

# Ensure PostgreSQL starts correctly in WSL (without systemd)
if [[ "$(uname -r)" == *"WSL"* ]]; then
    echo "Detected WSL environment. Starting PostgreSQL using service command."
    sudo service postgresql start
else
    echo "Starting PostgreSQL..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
fi

echo "Installation completed! Please restart your WSL session if this is the first time running this script."
