from dotenv import load_dotenv
import boto3
import json
import time
from sqlalchemy import Column, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import text
from random import randrange
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
    
from datetime import datetime


#bucket = "yahoo-auction-ids"
#key = "store-ids/auction-ids.csv"
#key = "store-ids/auction-ids.json"


# Load in json file of all links to scrape

def create_client():

    load_dotenv()
    AWS_SERVER_PUBLIC_KEY = os.getenv('aws_access_key_id')
    AWS_SERVER_SECRET_KEY =  os.getenv('aws_secret_access_key')
    REGION_NAME = 'us-east-1'
    s3_client = boto3.client('s3'
        ,aws_access_key_id=AWS_SERVER_PUBLIC_KEY
        ,aws_secret_access_key=AWS_SERVER_SECRET_KEY
        ,region_name=REGION_NAME
                      )
    return s3_client  

def load_my_s3_csv(bucket,key):
    


    s3_client = create_client()
    try:
        s3_object = s3_client.get_object(Bucket = bucket, Key = key)
    except Exception as e: 
        print(e)
    print(key)
    print(bucket)
    try:
        s3_object = s3_client.get_object(Bucket = bucket, Key = key)
    except Exception as e:
        print('Failure at loading in json object', e)
    #print(s3_object)
    #data = s3_object['Body'].read().decode('utf-8').splitlines()[1:]
    try:
        _l = json.loads(s3_object['Body'].read())
        data = [x['auction_id'] for x in _l]
        return data

    except Exception as e:
        print('Accessed object, but issue parsing', e)
        return None



"""Database engine & session creation."""


# Create connection to db to check for duplicate values already in the db 
def create_connection_rds():
    load_dotenv()

    drivername = 'postgresql'
    user = os.getenv('user')
    passwd= os.getenv('passwd')
    host= os.getenv('host')
    port= os.getenv('port')
    db_name= os.getenv('db_name')

    CONNECTION_STRING = f'{drivername}://{user}:{passwd}@{host}:{port}/{db_name}'

    try:
        engine = create_engine(CONNECTION_STRING)
        Session = sessionmaker(bind=engine)
        session = Session()
    except Exception as e:
        print('Cannot connect to the database',e)

    
    return session,engine

# intitate connection
def db_connect():
    """
    Performs database connection using database settings from settings.py.
    Returns sqlalchemy engine instance
    """
    return create_engine(CONNECTION_STRING)


# create tables in db
def create_table(Base,engine):
    Base.metadata.create_all(engine)
    

# run all functions together and then run query against db to remove dupes
def drop_dup_ids(data):
    

    #drop duplicates in initial data
    data = list(set(data))

    # create our sqlalchemy session and engine
    session, engine = create_connection_rds()
    

    Base = declarative_base()
    # defined temp table to insert our list of links and compare against our db
    class _temp_table(Base):
        __tablename__ = "_temp_table"
        auction_id = Column('auction_id', String(15),primary_key=True)

    try:
        Base.metadata.drop_all(bind = engine, tables = [_temp_table.__table__])
        session.commit()
    except Exception:
        pass    
    # create table and adddata into table for query
    try:
        create_table(Base,engine)
        for x in data:
            _t = _temp_table()
            _t.auction_id = x
            session.add(_t)
        session.commit()
    except:
        session.rollback()
        session.close()
        raise

    # execute query to return only data not in our db
    try:
        records = session.execute(text(
            f'SELECT DISTINCT auction_id FROM _temp_table WHERE auction_id NOT IN (SELECT auction_id from card_sales_staging)'))
        unique_data = [x[0] for x in records.all()]
        print(len(unique_data))
    except:
        print('could not complete id query')
    # close query transaction and then delete temp table from db and return our unique values
    finally:
        session.rollback()
        Base.metadata.drop_all(bind = engine, tables = [_temp_table.__table__])
        session.close()
        return unique_data
    
#verified_data = drop_dup_ids(data)

def create_id_s3_feed(bucket, input_folder, key, output_folder):
    
    #load data in
    try:
        data = load_my_s3_csv(bucket,f'{input_folder}{key}')
    except:
        return None
    
    if data is None:
        print('cant get data from file')
        return None
    if len(data) == 0:
        print('No ids to scrape')
        return None
    #quary ids against database
    verified_data = drop_dup_ids(data)
    if len(verified_data) == 0:
        print('No unique ids to scrape')
        return None
    _c = 0

    while len(verified_data) != 0:

        sleeping= randrange(200,250)
        s3_client = create_client()
        _c += 1 
        _key = f'{output_folder}yahoo_auction_id_{_c}.json'
        print(_key)
        _temp = json.dumps(verified_data[:25])
        verified_data = verified_data[25:]
        s3_client.put_object(Body = _temp, Bucket = bucket, Key = _key)
        print(f'napping for:{sleeping} seconds, {len(verified_data)} ids left!')
        time.sleep(sleeping)
    print('finished!')
    
    
    missed_data = drop_dup_ids(data)
    print(len((missed_data)))
    
    if len(missed_data) > 1:
        try:
            s3_client = create_client()
        except Exception as e:
            print('falure to connect to client',e)
        _d = datetime.today().strftime('%m-%d-%y')

        fail_key = f"failed-ids/auction-ids_failed_{_d}.json"

        data_json = json.dumps(missed_data, default=str)
        try:
            s3_client.put_object(Body = data_json, Bucket = bucket, Key = fail_key)   
        except Exception as e: 
            print('Something went wrong importing the file',e) 



if __name__ == '__main__':
    create_id_s3_feed(bucket, input_folder, key, output_folder)
