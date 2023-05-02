from sqlalchemy import create_engine, Column, Table, ForeignKey, MetaData
from sqlalchemy.ext.mutable import MutableList
from sqlalchemy.dialects.postgresql import ARRAY

from sqlalchemy.orm import relationship
from sqlalchemy.orm import scoped_session, sessionmaker

from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import (
    Integer, String, Date, DateTime, Float, Boolean, Text)
from scrapy.utils.project import get_project_settings
import os 
from dotenv import load_dotenv



#Get DB username/password
drivername=os.environ['drivername']
user= os.environ['user']
passwd= os.environ['passwd']
host= os.environ['host']
port= os.environ['port']
db_name= os.environ['db_name']
#con_string = os.environ['connectionstring']
#print(type(os.environ['connectionstring']))
#CONNECTION_STRING3 = con_string
try:
    CONNECTION_STRING = f'{drivername}://{user}:{passwd}@{host}:{port}/{db_name}'
except:
    print('having issues with connection_string/env vars')
#print(CONNECTION_STRING)


Base = declarative_base()

def db_connect():
    """
    Performs database connection using database settings from settings.py.
    Returns sqlalchemy engine instance
    """
    print('models ran')
    try:
        return create_engine(CONNECTION_STRING)
    except:
        print('Cannot connect to db')
        end()



def create_table(engine):
    Base.metadata.create_all(engine)
    



class Sold_Listings_Holding(Base):
    __tablename__ = "card_sales_staging"
    # __tablename__ = 'sold_listings_holding'

    id = Column(Integer, primary_key=True)
    auction_id = Column('auction_id', String(15),unique=True)
    title = Column('title', String(1000),nullable=False)
    price = Column('price', String(15))
    bids = Column('bids', Integer)
    tax = Column('tax', String(25))
    condition = Column('condition', String(25))
    auction_start = Column('auction_start', String(25))
    auction_end = Column('auction_end', String(25))
    auction_extension = Column('auction_extension', String(14))
    best_offer_accepted = Column('best_offer_accepted', String(13))
    categories = Column('categories', String(10000),nullable=False)
    flag = Column('flag', String(8)) 
    scrape_time = Column('scrape_time', DateTime)
    all_images = Column('all_images', String(10000),nullable=False)