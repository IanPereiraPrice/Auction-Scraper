from dotenv import load_dotenv
import time
import os
import scrapy
from scrapy.crawler import CrawlerProcess
from scrapy.crawler import CrawlerRunner
from scrapy.loader import ItemLoader
from twisted.internet import reactor
import re
import boto3
import json
import sys
from scrapy.http.request import Request
#from crochet import setup, wait_for
from scrapy.utils.log import configure_logging
#from multiprocessing import Process, Queue
from billiard import Process, Queue


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
    

    print(s3_client)
    #s3_client = create_client()
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
    
class 青眼の白龍_SM_51_sold_spider(scrapy.Spider):
    name = 'BEWD'
    allowed_domains = ['auctions.yahoo.co.jp']
    custom_settings = {'DOWNLOAD_DELAY':15}
    
    #Create urls to scrape, and pass last scraped item into the spider to stop spider once reached
    def start_requests(self):
       print('Here:',self.dict)
       for key, val in self.dict.items():
            search_term = key.strip().replace(' ', '+')
            search_term = f'https://auctions.yahoo.co.jp/closedsearch/closedsearch?va={search_term}&b=1&n=100&select=6&auccat=&34&auccat=2084005059&min=100'
            self.c = 0

            yield Request(search_term,self.parse,cb_kwargs={'key':key, 'val':val})
    

    custom_settings = {'DOWNLOAD_DELAY':10}
    def parse(self,response,key,val):

        c = self.c


        print(f'currently scrapping {key}')


        all_links = response.xpath('//h3//a/@href').extract()
        for link in all_links:
            c += 1
            auction_id = re.search(r'(?<=auction/)\w+',link).group(0)
            # Un Comment this block to not double scrape links
            if auction_id == val:
                print('There is a dupe!')
                print(f'found all ids for {key}')

                return None
            elif c == 1: 
                self.dict[key] = auction_id
                continue
            else:
                yield {'auction_id' : auction_id}

        try:     
            print('going to the next page')
            next_page = response.xpath("//a[text() = '次へ']/@href").extract_first()
        except Exception as e:
            print('next page not found',e)
        try:
            print('next page reached')
            yield scrapy.Request(next_page,self.item_parse,cb_kwargs={'key':key, 'val':val})
        except Exception as e:
            print('next page response failed',e)

    def item_parse(self,response,key,val):
        print(f'currently scrapping {key}')


        all_links = response.xpath('//h3//a/@href').extract()
        for link in all_links:


            auction_id = re.search(r'(?<=auction/)\w+',link).group(0)
            # Un Comment this block to not double scrape links
            if auction_id == val:
                print('There is a dupe!')
                print(f'found all ids for {key}')
                return None
            else:
                yield {'auction_id' : auction_id}

        try:     
            print('going to the next page')
            next_page = response.xpath("//a[text() = '次へ']/@href").extract_first()

        except Exception as e:
            print('next page not found',e)
        try:
            print('next page reached')
            yield scrapy.Request(next_page,self.item_parse,cb_kwargs={'key':key, 'val':val})
        except Exception as e:
            print('next page response failed',e)
            return None
        
# put updated dictionary into s3 bucket for the next time we scrape
def insert_json_s3(data,bucket,key,s3_client):
    data_json = json.dumps(data, default=str)
    s3_client.put_object(Body = data_json, Bucket = bucket, Key = key)     




# the wrapper to make it run more times

def crawl_spider(spider,data,bucket,key,output_folder):
    load_dotenv()
    AWS_SERVER_PUBLIC_KEY = os.getenv('public-access-key')
    AWS_SERVER_SECRET_KEY =  os.getenv('private-key')
    
    new_data = data
    def f(q):
        try:
            runner = CrawlerRunner(settings={'FEEDS':{f's3://{bucket}/{output_folder}auction-ids.json': {'format': 'json'}}
                ,'AWS_ACCESS_KEY_ID':AWS_SERVER_PUBLIC_KEY
                ,'AWS_SECRET_ACCESS_KEY':AWS_SERVER_SECRET_KEY})
            deferred = runner.crawl(spider, input='inputargument', dict = data)
            deferred.addBoth(lambda _: reactor.stop())
            reactor.run()


            s3_client = create_client()
            temp_key = key.replace('.json','_temp.json')
            insert_json_s3(data,bucket,temp_key,s3_client)

            print('Inner_data:',data)
            q.put(None)
        except Exception as e:
            q.put(e)

    q = Queue()
    p = Process(target=f, args=(q,))
    p.start()
    result = q.get()
    p.join()
    print('Outside new data:',new_data)
    print('Outer_data:',data)
    if result is not None:
        raise result
     
    
    
def run_spider(bucket,key,output_folder):    
   
    #create client
    
    s3_client = create_client()
    #load json dict
    data = load_my_s3_json(bucket,key,s3_client)
    temp_key = key.replace('.json','_temp.json')
    #print(len(data))
    
    
    #run spider
    
    print('starting up spider!')
    #try :
    
    configure_logging()
    crawl_spider(青眼の白龍_SM_51_sold_spider,data,bucket,key,output_folder)
    print('success! spider ran')
    #except Exception as e:

        #print(f'could not run spider:{e}, heres the data:{data}')


   # if state_run > 0:
        #print('slpet, and herse data:',data)
        #update json
   # insert_json_s3(new_dict,bucket,temp_key,s3_client)
    print('done? now updated temp_dict')


if __name__ == '__main__':
    print('name is main')
    run_spider(bucket,key,output_folder)

else:
    print('we cant start')

