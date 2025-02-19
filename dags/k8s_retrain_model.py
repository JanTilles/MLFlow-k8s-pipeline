from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from datetime import datetime

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2024, 2, 17),
    'retries': 1,
}

dag = DAG(
    'k8s_retrain_model',
    default_args=default_args,
    schedule_interval=None,  # Only triggered when drift is detected
    catchup=False
)

train_task = KubernetesPodOperator(
    namespace="airflow",
    image="localhost:5000/retrain-image:v1",
    cmds=["python", "/app/retrain.py"],
    name="retrain-task",
    task_id="train_model_in_k8s",
    get_logs=True,
    dag=dag
)

train_task