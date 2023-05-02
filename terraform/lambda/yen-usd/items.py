from scrapy.item import Item, Field
from itemloaders.processors import MapCompose
from itemloaders.processors import TakeFirst
from itemloaders.processors  import Join
from datetime import datetime


def fix_date_format(date):
    try:
        date = datetime.strptime(date,'%b %d, %Y').strftime('%m/%d/%y')
        return date
    except Exception as e:
        print('can not fix the date')
        return None
    


class yen_usd_item(Item):
    date = Field(input_processor=MapCompose(fix_date_format), output_processor=TakeFirst())
    open = Field(output_processor=TakeFirst())
    high = Field(output_processor=TakeFirst())
    low = Field(output_processor=TakeFirst())
    close = Field(output_processor=TakeFirst())
    
    
    pass