import sys
import os
from datetime import datetime, timedelta

#insert path in order to avoid issues with finding files on docker
sys.path.insert(0,os.path.abspath(os.path.dirname('link_feeder.py')))

from link_feeder import create_id_s3_feed
from Scrape_yahoo_search import run_spider
from update_dict import insert_final


from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

from dotenv import load_dotenv

DBT_DIR = "/opt/airflow/transform/data_warehouse"

load_dotenv()

#locations of files for functions
bucket_1 = os.getenv('bucket-1')
folder_dict = os.getenv('folder-1')
search_dict = os.getenv('file-search-dict')
folder_store_id = os.getenv('folder-2')
folder_id_to_lambda = os.getenv('folder-3')




default_args = {
    "owner": "airflow",
    "depends_on_past": True,
    "wait_for_downstream": True,
    "start_date": datetime(2023,3, 3),
    "catchup_by_default": False,
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=1),
}
dag = DAG(
    "scrape_auction_sites",
    default_args=default_args,
    catchup = False,
    schedule_interval="0 0 * * *",
    dagrun_timeout = timedelta(minutes=360),
    max_active_runs=1,
)

#Initial python function to retrieve auction ids from all of our saved searches
#Currently drops file into S3 but will change to do locally to reduce memory usage
yahoo_ids_to_s3 = PythonOperator(
    dag=dag,
    task_id="yahoo_ids_to_s3",
    python_callable= run_spider,
    op_kwargs={
        "key": search_dict
        ,"bucket": bucket_1
        ,"output_folder": folder_store_id
    },
)

#Python function to drip feed auction ids into lambda function which scrapes item info.
#Currently runs in 25 item batches on ~3 minute delay to not get banned
s3_ids_to_lambda = PythonOperator(
    dag=dag,
    task_id="s3_ids_to_lambda",
    python_callable=create_id_s3_feed,
    op_kwargs={

        "bucket": bucket_1,
        "key": 'auction-ids.json',
        "input_folder": folder_store_id,
        "output_folder": folder_id_to_lambda,
    },
    depends_on_past=True,
)

#After all items processed, updates our old dict to have latest scraped items for searches
update_dict = PythonOperator(
    dag=dag,
    task_id="update_dict",
    python_callable= insert_final,
    op_kwargs={
        "key": search_dict
        ,"bucket": bucket_1
    },
    depends_on_past=True,
)

#Runs multiple SQL queries to clean and return data in state for dashboards
transform_data_dbt = BashOperator(
    dag=dag,
    task_id="transform_data_dbt",
    bash_command=f"cd {DBT_DIR} && source dbt.env && dbt run"
)


#End of the pipeline, run successful
end_of_data_pipeline = DummyOperator(task_id="end_of_data_pipeline", dag=dag)



#Functions ran sequentially in the order that the functions are listed.
yahoo_ids_to_s3 >> s3_ids_to_lambda >> update_dict >> transform_data_dbt >> end_of_data_pipeline
