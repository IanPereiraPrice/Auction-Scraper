# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html




from scrapy.item import Item, Field
from itemloaders.processors import MapCompose
from itemloaders.processors import TakeFirst
from itemloaders.processors  import Join
from datetime import datetime



def strip_price(text):
    text_edit = text.strip()
    text_edit = text_edit.replace(',','')
    return text_edit

def strip_tax(text):
    text_edit = text.strip()
    text_edit = text_edit.replace('税込','')
    text_edit = text_edit.replace('税','')
    text_edit = text_edit.replace('(','')
    text_edit = text_edit.replace(')','')
    # text = text.rstrip(1)
    text_edit = text_edit.replace(',','')
    return text_edit

def strip_bids(text):
    if text  == '終了':
        text_edit = 0
    else:
        text_edit = text.replace('件','')
    
    return text_edit

    
#Clean Yahoo Auction Times
def remove_char(str, n):
    first_part = str[:n] 
    last_part = str[n+3:]
    full = f'{first_part} {last_part}'
    return full  

    
def strip_time(text):
    text = strip_price(text)
    text = remove_char(text, 10)
    #return datetime.strptime(text, '%y.%m.%d %H:%M')
    return text
        

def image_matrix(text):
    item_image_list = []
    for image in text:
        item_image_list.append(image)
    return item_image_list


class CardScraperItem(Item):
    auction_id = Field(output_processor=TakeFirst())
    title = Field(output_processor=TakeFirst())
    price = Field(input_processor=MapCompose(strip_price),
        output_processor=TakeFirst())
    bids = Field(input_processor=MapCompose(strip_bids),output_processor=TakeFirst())
    tax = Field(input_processor=MapCompose(strip_tax),output_processor=TakeFirst())
    condition = Field(input_processor=MapCompose(strip_price),
        output_processor=TakeFirst())
    auction_start = Field(input_processor=MapCompose(strip_time),
        output_processor=TakeFirst())
    auction_end = Field(input_processor=MapCompose(strip_time),
        output_processor=TakeFirst())
    auction_extension = Field(output_processor=TakeFirst())
    best_offer_accepted = Field(output_processor=TakeFirst())
    # all_images = Field(input_processor=MapCompose(strip_price))
    # image_list = Field(input_processor=MapCompose(image_matrix))
    categories = Field()
    flag = Field(output_processor=TakeFirst())
    scrape_time = Field(output_processor=TakeFirst())
    image_list = Field(output_processor=Join())
    
    pass
