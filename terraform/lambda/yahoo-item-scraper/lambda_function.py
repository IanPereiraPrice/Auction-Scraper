import json
import boto3
import csv
import io
from scrapy.utils.log import configure_logging
from time import gmtime, strftime


# Define your item pipelines here
import sys
import os 
from dotenv import load_dotenv

from sqlalchemy.orm import sessionmaker


import sys
# insert at 1, 0 is the script path (or '' in REPL)

from card_scraper.models import db_connect
from card_scraper.models import create_table
from card_scraper.models import Sold_Listings_Holding
import logging
import scrapy
import sys    
from scrapy.utils.project import get_project_settings
from scrapy.spiderloader import SpiderLoader
from scrapy.crawler import CrawlerProcess
from scrapy.crawler import CrawlerRunner
from scrapy.loader import ItemLoader
from twisted.internet import reactor

import re
#import pandas as pd
import boto3
#import numpy
import dotenv
import os

import imp
from card_scraper.items import CardScraperItem
from card_scraper.pipelines import Yahoo_Listings_Pipeline
from card_scraper.spiders.yahoo import get_links
from card_scraper.spiders.yahoo import 青眼の白龍_SM_51_sold_spider





def lambda_handler(event, context):
    #sys.exit(0)
    bucket  = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    #bucket = 's3-lambda-test-bucket-yahoo'
    #key = 'yahoo-ids-scrape/yahoo_auction_id_1.json'
    
    print(key)
    print(bucket)
    #s3_client = boto3.client('s3')
    print('?')
    
      

    def load_my_s3_json(bucket,key):
        
          
    
        s3_client = boto3.client('s3')
        try:
            s3_object = s3_client.get_object(Bucket = bucket, Key = key)
        except Exception as e: 
            print(e)
        _temp = s3_object['Body'].read().decode('utf-8')
        data  = json.loads(_temp)
        return data
    s3_client = boto3.client('s3')
    data = load_my_s3_json(bucket,key)
    _k = data
    print(_k)
    
    scrape_time = strftime("%Y-%m-%d %H:%M:%S", gmtime())
    process = CrawlerProcess(get_project_settings())
    process.crawl(青眼の白龍_SM_51_sold_spider, input='inputargument', links_df = _k, time = scrape_time)
    process.start()
    print('key here:',key)
    print('bucket here:',bucket)
    try :
        delete_object = s3_client.delete_object(Bucket = bucket, Key = key)
    except Exception as e:
        print('all links parsed, couldnt access item', e)

    try: 
        print('run was successful')
        sys.exit(0)
    except Exception as e:
        print(e)
        sys.exit(1)
    #if "twisted.internet.reactor" in sys.modules:
    #    del sys.modules["twisted.internet.reactor"]
    
    
    