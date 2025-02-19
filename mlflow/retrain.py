import mlflow
import mlflow.sklearn
import pandas as pd
import psycopg2
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

def fetch_data():
    conn = psycopg2.connect(
        dbname="yourdb",
        user="youruser",
        password="yourpassword",
        host="your-postgres-host",
        port="5432"
    )
    query = "SELECT * FROM new_training_data WHERE drift_detected = TRUE"
    df = pd.read_sql(query, conn)
    conn.close()
    return df

df = fetch_data()
X = df.drop(columns=["target"])
y = df["target"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

mlflow.set_experiment("retrain_experiment")
with mlflow.start_run():
    model = RandomForestClassifier(n_estimators=100)
    model.fit(X_train, y_train)
    mlflow.sklearn.log_model(model, "new_model")
    acc = model.score(X_test, y_test)
    mlflow.log_metric("accuracy", acc)

print(f"New model trained with accuracy: {acc}")