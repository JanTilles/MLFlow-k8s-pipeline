import mlflow
import mlflow.sklearn
import os
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

mlflow.set_experiment("iris_classification")

X, y = load_iris(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

with mlflow.start_run():
    model = RandomForestClassifier(n_estimators=100)
    model.fit(X_train, y_train)
    mlflow.sklearn.log_model(model, "iris_model")
    acc = model.score(X_test, y_test)
    mlflow.log_metric("accuracy", acc)

# Save model locally for containerization
model_path = "iris_model"
mlflow.sklearn.save_model(model, model_path)

print(f"Model trained and saved at {model_path}")

# Create serving script
serve_script = """from flask import Flask, request, jsonify
import mlflow.pyfunc

app = Flask(__name__)
model = mlflow.pyfunc.load_model("iris_model")

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    predictions = model.predict(data['features'])
    return jsonify({'predictions': predictions.tolist()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
"""

with open("serve_model.py", "w") as f:
    f.write(serve_script)

# Create Dockerfile for serving
dockerfile_content = """FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY serve_model.py .
COPY iris_model /app/iris_model
CMD ["python", "serve_model.py"]
"""

with open("Dockerfile", "w") as f:
    f.write(dockerfile_content)

# Create requirements.txt
requirements = """flask
mlflow
pandas
scikit-learn
"""

with open("requirements.txt", "w") as f:
    f.write(requirements)

# Build and push Docker image
os.system("docker build -t localhost:5000/iris-model:v1 .")
os.system("docker push localhost:5000/iris-model:v1")

print("Docker image built and pushed successfully!")
