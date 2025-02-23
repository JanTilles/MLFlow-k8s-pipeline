# MLflow + Kubernetes Pipeline

This repository contains all the necessary files to deploy an MLflow-based training and inference pipeline on Kubernetes.

## **🔹 Installation Steps**

### **📌 Ubuntu (WSL) Installation**
1. **Extract the ZIP file** and navigate to the project folder:
   ```bash
   unzip mlflow_k8s_pipeline.zip
   cd mlflow_k8s_pipeline
   ```
2. **Make the install script executable and run it:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
   This will **check and install missing dependencies**, including:
   - Python, Docker, Kubernetes (kubectl), Helm, PostgreSQL
   - Kind (for local Kubernetes cluster)
   - Local Docker Registry (`localhost:5000`)
   - MLflow, Apache Airflow, and Evidently AI

3. **Activate the Virtual Environment (if needed)**  
   - The install script does not create a virtual environment by default.  
   - If you want to use a virtual environment while still accessing system-wide packages, create one:  
     ```bash
     python3 -m venv venv --system-site-packages
     source venv/bin/activate
     ```

---

## **🔹 Deploying Everything to Kubernetes**

### **Step 1: Build and Push the Model Image**
1. **Train the model and build a Docker image**:
   ```bash
   python mlflow/train.py
   ```
   This will:
   - Train an ML model
   - Save the model locally in `iris_model/`
   - Build and push the model as a **Docker image to `localhost:5000/iris-model:v1`**

### **Step 2: Deploy the Model to KServe**
1. **Apply the KServe inference service YAML**:
   ```bash
   kubectl apply -f k8s/kserve_model.yaml
   ```
2. **Check the deployment status**:
   ```bash
   kubectl get inferenceservices
   ```
   Once `STATUS` shows **READY**, your model is successfully deployed! 🚀

---

## **🔹 Using the ML Model Service**

### **Send a Prediction Request**
Once the model is running, you can send data to the deployed service.

1. **Get the external URL of the model service:**
   ```bash
   kubectl get inferenceservice iris-classifier
   ```
   Look for the `STATUS.URL` field.

2. **Make a request using `curl` (replace `<URL>` with actual URL):**
   ```bash
   curl -X POST "<URL>/predict" -H "Content-Type: application/json" -d '{
       "features": [[5.1, 3.5, 1.4, 0.2]]
   }'
   ```
3. **Expected response:**
   ```json
   {"predictions": [0]}
   ```

---

## **🔹 Monitoring & Retraining**
### **Detecting Model Drift**
1. **Run Evidently AI to check for drift:**
   ```bash
   python monitoring/drift_detection.py
   ```
   If drift is detected, it will **trigger data collection for retraining**.

### **Retraining the Model**
1. **Trigger retraining manually (or via Airflow DAG):**
   ```bash
   python mlflow/retrain.py
   ```
2. **Rebuild and push the new model image:**
   ```bash
   docker build -t localhost:5000/iris-model:v2 .
   docker push localhost:5000/iris-model:v2
   ```
3. **Update KServe deployment to use the new model image:**
   ```bash
   kubectl set image deployment/iris-classifier iris-model=localhost:5000/iris-model:v2
   ```

---

## **🔹 Stopping & Cleaning Up**
1. **Delete the deployed model service:**
   ```bash
   kubectl delete -f k8s/kserve_model.yaml
   ```
2. **Stop Minikube (if running locally):**
   ```bash
   minikube stop
   ```
3. **Stop and remove the local Docker registry:**
   ```bash
   docker stop registry && docker rm registry
   ```

---

## **🔹 Troubleshooting**
### **1. Model Service Not Accessible?**
- Ensure the service is running:
  ```bash
  kubectl get inferenceservices
  ```
- If it's **not ready**, check logs:
  ```bash
  kubectl logs -l serving.kserve.io/inferenceservice=iris-classifier
  ```

### **2. Docker Image Push Fails?**
- Make sure the local registry is running:
  ```bash
  docker ps | grep registry
  ```
- Restart the registry if necessary:
  ```bash
  docker run -d -p 5000:5000 --restart=always --name registry registry:2
  ```

### **3. Airflow DAGs Not Running?**
- Start Airflow manually:
  ```bash
  airflow standalone
  ```
- Check DAG logs:
  ```bash
  airflow dags list
  airflow tasks logs k8s_retrain_model train_model_in_k8s
  ```

---

## **✅ Congratulations! You’ve Successfully Deployed MLflow + KServe on Kubernetes 🚀**

Now, you can **train models, detect drift, retrain, and serve predictions** with full automation! 🎯

