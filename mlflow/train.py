import mlflow
import mlflow.sklearn
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

print("Model trained and logged successfully!")