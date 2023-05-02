from sqlalchemy import create_engine, Column, Table, ForeignKey, MetaData
from sqlalchemy.orm import relationship
from sqlalchemy.orm import scoped_session, sessionmaker

from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import (
    Integer, String, Date, DateTime, Float, Boolean, Text)
from sqlalchemy.types import NullType
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

CONNECTION_STRING = f'{drivername}://{user}:{passwd}@{host}:{port}/{db_name}'

Base = declarative_base()

def testing():
    return CONNECTION_STRING



def db_connect():
    """
    Performs database connection using database settings from settings.py.
    Returns sqlalchemy engine instance
    """
    print('models ran')
    return create_engine(CONNECTION_STRING)



def create_table(engine):
    Base.metadata.create_all(engine)

class yen_usd_model(Base):
    __tablename__ = "yen_to_usd"
    
    date = Column('date', Date, primary_key=True,unique=True)
    open = Column('open', Float)
    high = Column('high', Float)
    low = Column('low', Float)
    close = Column('close',Float)

    
