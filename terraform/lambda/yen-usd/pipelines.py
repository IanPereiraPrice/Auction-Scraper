# Define your item pipelines here
import sys
import os 
from dotenv import load_dotenv

from sqlalchemy.orm import sessionmaker
from scrapy.exceptions import DropItem

import sys
# insert at 1, 0 is the script path (or '' in REPL)

from models import db_connect
from models import create_table
from models import yen_usd_model
import logging

class yen_usd_pipeline(object):
    def __init__(self):
        """
        Initializes database connection and sessionmaker
        Creates tables
        """
        try:
            engine = db_connect()
            create_table(engine)
            
            self.Session = sessionmaker(bind=engine)
        except Exception as e:
            print('connection to db issue:',e)
            return None

    #def process_item(self, item, spider):
    def process_item(self, item):
        #print('yen_usd_pipeline ran')
        try:
            session = self.Session()
            print('test',item['date'])
            exist_id = session.query(yen_usd_model).filter_by(date = item['date']).first()
            session.close()
            print('successfully verified date')
        except Exception as e:
            print('could not execute date query on db:',e)
            exist_id = 'f'
        #Validate that date is new else end scrape
        #exist_id = None
        

        if exist_id is not None:  
            try:
                print('duplicate found')
                raise DropItem("Duplicate item found: %s" % item['date'])
                session.close()
            except Exception as e:
                print('something likely broken with our item:',e)
                try:
                    session.close()
                except Exception as e:
                    print('our session is messed up:',e)
                    
                    return None
        else:
            print('new value')
            session = self.Session()
            yen_usd_item = yen_usd_model()
            

            yen_usd_item.date = item['date'],
            yen_usd_item.open = item['open'],
            yen_usd_item.high = item['high'],
            yen_usd_item.low = item['low'],
            yen_usd_item.close = item['close']
            
            print(yen_usd_item.date)
            try:
                
                session.add(yen_usd_item)
                session.commit()
                print('successful')
            except Exception as e:
                print('error:',e)
                session.rollback()
                raise
    
            finally:
                session.close()

                return item 