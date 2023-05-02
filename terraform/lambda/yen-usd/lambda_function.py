import json

# Define your item pipelines here
import sys
import os 
from dotenv import load_dotenv

from sqlalchemy.orm import sessionmaker


import sys
# insert at 1, 0 is the script path (or '' in REPL)

from models import db_connect
from models import create_table
#from models import yen_usd
import logging

import scrapy

import sys    
from scrapy.utils.project import get_project_settings
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
import sys
import imp
from items import yen_usd_item
from pipelines import yen_usd_pipeline
from scrapy.http.request import Request
import datetime
#from crochet import setup, wait_for

if "twisted.internet.reactor" in sys.modules:
    del sys.modules["twisted.internet.reactor"]
#setup()

from datetime import datetime

class yen_usd_spider(scrapy.Spider):
    
    
    name = 'card_scraper'
    start_urls = ['https://finance.yahoo.com/quote/JPY%3DX/history?p=JPY%3DX']
    #start_urls = ['https://www.wsj.com/market-data/quotes/fx/USDJPY/historical-prices']
    #print(get_links(links_df))
    
    custom_settings = {'DOWNLOAD_DELAY':3}
    
    def start_requests(self):
        headers= {'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/109.0'}
        for url in self.start_urls:
            try:
                yield Request(url, headers=headers)
            except Exception as e:
                print('failed to reach page:',e)
                return None
    

    def parse(self,response):
        print("We Are Scraping:")
        '''_d = response.xpath(".//table[@class = 'cr_dataTable']//tr[1]/td[1]/text()").extract_first()
        _d = datetime.strptime(_d,'%m/%d/%y').date().strftime('%m/%d/%y')
        print(datetime.now())
        _actual_date = datetime.now().replace(hour=0).strftime('%m/%d/%y')
        
        print('todays date:',_actual_date)
        print('scraped date',_d)
        print('wtf is going on',type(_d),type(_actual_date))
        if _d != _actual_date:
            print("nothing here", _d)
            return None'''
            
        #else:
        #print('here we go')
        _d1 = response.xpath("//table[@data-test = 'historical-prices']//tr[1]/td[1]/span[1]//text()").extract_first()
        _d2 = response.xpath("//table[@data-test = 'historical-prices']//tr[1]/td[2]/span[1]//text()").extract_first()
        _d3 = response.xpath("//table[@data-test = 'historical-prices']//tr[1]/td[3]/span[1]//text()").extract_first()
        _d4 = response.xpath("//table[@data-test = 'historical-prices']//tr[1]/td[4]/span[1]//text()").extract_first()
        _d5 = response.xpath("//table[@data-test = 'historical-prices']//tr[1]/td[5]/span[1]//text()").extract_first()
        #print(_d.strftime('%m/%d/%y'))
        print("date:",_d1,'open:',_d2,'high:',_d3,'low',_d4,'close',_d5)
        
        
        
        
        
        
        '''l.add_xpath('date',f".//table[@class = 'cr_dataTable']//tr[1]/td[1]/text()")
        l.add_xpath('open',f".//table[@class = 'cr_dataTable']//tr[1]/td[2]/text()")
        l.add_xpath('high',f".//table[@class = 'cr_dataTable']//tr[1]/td[3]/text()")
        l.add_xpath('low',f".//table[@class = 'cr_dataTable']//tr[1]/td[4]/text()")
        l.add_xpath('close',f".//table[@class = 'cr_dataTable']//tr[1]/td[5]/text()")'''
        
        #.add_value(_d1)
        
        
        l = ItemLoader(item=yen_usd_item(), response=response)
        l.add_value('date',_d1)
        l.add_value('open',_d2)
        l.add_value('high',_d3)
        l.add_value('low',_d4)
        l.add_value('close',_d5)
        
        try:
            
            _t = yen_usd_pipeline()
            _t.process_item(l.load_item())
        except Exception as e:
            print('idk whats wrong with our pipeline:',e)
            yield l.load_item()
            #return None
        
        
        
        
        
        
        
        
        
        '''
        l = ItemLoader(item=yen_usd_item(), response=response)
        l.add_xpath('date',"//table[@data-test = 'historical-prices']//tr[1]/td[1]/span[1]//text()")
        l.add_xpath('open',"//table[@data-test = 'historical-prices']//tr[1]/td[2]/span[1]//text()")
        l.add_xpath('high',"//table[@data-test = 'historical-prices']//tr[1]/td[3]/span[1]//text()")
        l.add_xpath('low',"//table[@data-test = 'historical-prices']//tr[1]/td[4]/span[1]//text()")
        l.add_xpath('close',"//table[@data-test = 'historical-prices']//tr[1]/td[5]/span[1]//text()")
        
        _t = yen_usd_pipeline()
        _t.process_item(l.load_item())
        '''
        
            
            
            
        '''_list = response.xpath(".//table[@class = 'cr_dataTable']//tr/td[1]/text()").extract()
        
        
        
        for x,_y in enumerate(_list):
            print(x,_y)
            while x<2:
            
                l = ItemLoader(item=yen_usd_item(), response=response)
                l.add_xpath('date',f".//table[@class = 'cr_dataTable']//tr[{x}]/td[1]/text()")
                l.add_xpath('open',f".//table[@class = 'cr_dataTable']//tr[{x}]/td[2]/text()")
                l.add_xpath('high',f".//table[@class = 'cr_dataTable']//tr[{x}]/td[3]/text()")
                l.add_xpath('low',f".//table[@class = 'cr_dataTable']//tr[{x}]/td[4]/text()")
                l.add_xpath('close',f".//table[@class = 'cr_dataTable']//tr[{x}]/td[5]/text()")
                    
                    
                _t = yen_usd_pipeline()
                #print(_t)
                _t.process_item(l.load_item())
                #yield l.load_item()
            pass
            #return l.load_item()'''
        
        pass
        
def lambda_handler(event, context):
    #sys.exit(0)
    process = CrawlerProcess()
    process.crawl(yen_usd_spider)

    try:
        process.start()
    except Exception as e: 
        sys.exit(0)
    try: 
        print('run was successful')
        sys.exit(0)
    except Exception as e:
        print(e)
        sys.exit(1)
