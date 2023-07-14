
import json
from dotenv import load_dotenv
import boto3
import os

def create_client():

    load_dotenv()
    AWS_SERVER_PUBLIC_KEY = os.getenv('public-access-key')
    AWS_SERVER_SECRET_KEY =  os.getenv('private-key')
    REGION_NAME = os.getenv('region-name')
    s3_client = boto3.client('s3'
        ,aws_access_key_id=AWS_SERVER_PUBLIC_KEY
        ,aws_secret_access_key=AWS_SERVER_SECRET_KEY
        ,region_name=REGION_NAME
                      )
    return s3_client  


def load_my_s3_json(bucket,key,s3_client):
    

    #print(s3_client)
    s3_client = create_client()
    try:
        s3_object = s3_client.get_object(Bucket = bucket, Key = key)
    except Exception as e: 
        print(e)
        return None
    try:
        _temp = s3_object['Body'].read().decode('utf-8')
        data  = json.loads(_temp)
        return data
    
    except Exception as e:
        print('Issue with data stucture',e)
        return None