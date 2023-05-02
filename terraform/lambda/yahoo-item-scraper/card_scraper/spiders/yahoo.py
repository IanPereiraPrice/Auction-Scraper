import json


# Define your item pipelines here
import sys
import os 
from dotenv import load_dotenv
from time import gmtime, strftime
from sqlalchemy.orm import sessionmaker


import sys
# insert at 1, 0 is the script path (or '' in REPL)

from card_scraper.models import db_connect
from card_scraper.models import create_table
from card_scraper.models import Sold_Listings_Holding
# from card_scraper.models import db_connect, create_table,sold_listings_holding
import logging




#

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

import imp
from card_scraper.items import CardScraperItem
from card_scraper.pipelines import Yahoo_Listings_Pipeline
#from card_scraper.pipelines import DuplicatesPipeline
from scrapy.http.request import Request



#from crochet import setup, wait_for


#setup()



def get_links(links):
    #links = pd.read_csv('E:\Ian\Ebay_Project\Yahoo_card_scraper\card_scraper\spiders\items.csv')
    link_list = []
    for link in links:
        link_list.append(f'https://page.auctions.yahoo.co.jp/jp/auction/{link}')
    return link_list


    #items_file = 'E:\Ian\Ebay_Project\Yahoo_card_scraper\card_scraper\spiders\items.csv'

class 青眼の白龍_SM_51_sold_spider(scrapy.Spider):
    #how dumb am I 
    
    
    name = 'card_scraper'
    allowed_domains = ['auctions.yahoo.co.jp']
    #print(get_links(links_df))
    
    custom_settings = {'DOWNLOAD_DELAY':3}


    def start_requests(self):
        
        print('Here:',self.links_df)
        for link in self.links_df:
            link = f'https://page.auctions.yahoo.co.jp/jp/auction/{link}'
            try:
                yield Request(link,self.parse)
            except Exception as e:
                print(e)


    def parse(self,response):
        l = ItemLoader(item=CardScraperItem(), response=response)
        l.add_xpath('auction_id',"//th[text() = 'オークションID']/following-sibling::td//text()")
        l.add_xpath('title','//*[@id="ProductTitle"]/div/h1//text()')
        l.add_xpath('price','//*[@id="l-sub"]//dd[contains(@class, "Price__value")]/text()')
        l.add_xpath('bids','//*[@class = "Count__detail"]/text()')
        l.add_xpath('categories','//ul[@class="Section__categoryList"]/*/a//text()')
        l.add_xpath('condition',"//th[text() = '状態']/following-sibling::td/a/text()")
        l.add_xpath('tax','//*[@id="l-sub"]//dd[contains(@class, "Price__value")]/span/text()')
        l.add_xpath('auction_start',"//th[text() = '開始日時']/following-sibling::td//text()")
        l.add_xpath('auction_end',"//th[text() = '終了日時']/following-sibling::td//text()")
        l.add_xpath('auction_extension',"//th[./a[text() = '自動延長']]/following-sibling::td//text()")
        l.add_xpath('best_offer_accepted',"//table[@class = 'Section__table']//th[./a[contains(text(),'早期終了')]]/following-sibling::td//text()")
        l.add_xpath('image_list','//div[contains(@class,"ProductImage__body")]//img/@src')
        _cats = response.xpath('//ul[@class="Section__categoryList"]/*/a//text()').extract()
        _cats_list = []
        for x in _cats:
            _cats_list.append(x)
        _flag = '【削除予定】' in _cats_list[-1]
        l.add_value('flag',_flag)
        l.add_value('scrape_time', self.time)
        
        print("We Are Scraping:")
        _t = Yahoo_Listings_Pipeline()
        _t.process_item(l.load_item())
        yield l.load_item()
        
    
        
    
