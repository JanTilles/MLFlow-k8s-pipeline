import evidently
from evidently.test_suite import TestSuite
from evidently.tests import TestDataDrift
import pandas as pd

df_train = pd.read_csv("s3://your-mlflow-bucket/training_data.csv")
df_new = pd.read_csv("s3://your-mlflow-bucket/new_data.csv")

data_drift = TestSuite(tests=[TestDataDrift()])
data_drift.run(reference_data=df_train, current_data=df_new)

if data_drift.as_dict()["tests"][0]["status"] == "FAIL":
    print("Drift detected!")