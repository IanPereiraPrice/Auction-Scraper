from load_s3_json.py import load_my_s3_json

load_my_s3_json()

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
import pathlib
import time
import random


#from load_s3_json.py import load_my_s3_json

class selenium_spider(dict):
    def __init__(self,dict):
        
        self.mercari_element_locations = {
            'search':{
                'href':{
                    'xpath':None
                    ,'attribute':'href'}
                ,'title':{
                    'xpath':'.//div/figure//div[@role = "img"]'
                    ,'attribute':'aria-label'}
                ,'price':{
                    'xpath':'.//div'
                    ,'attribute':None}
                }
        }
  
        
        self.dict = dict
        
        #set up chrome options for selenium. 'Headless driver for lambda use'        
        self.chrome_options = Options()
        self.chrome_options.add_argument('--headless')
        self.chrome_options.add_argument('window-size=1920x1080')
        
        #not in use
        #dir = pathlib.Path().resolve()
        
        # set up the webdriver service
        self.service = Service("/usr/lib/chromium-browser/chromedriver")
        
    def label_locations(self,item_method,item_attribute):
        xpath = self.mercari_element_locations[f'{item_method}'][f'{item_attribute}']['xpath']
        attribute = self.mercari_element_locations[f'{item_method}'][f'{item_attribute}']['attribute']
        return xpath, attribute      
        

    def start_search(self,key):
        
        self.driver = webdriver.Chrome(service=self.service,options=self.chrome_options)
        # create search link using dict of search keywords
        search_term = f'https://jp.mercari.com/search?keyword={key}&category_id=1152&status=sold_out&sort=created_time&order=desc'
        # start driver on intitial page
        self.driver.get(search_term)
        
    # used in retry element and handle stale error methods    
    def get_element(self,item,xpath,attribute):
        if xpath == None:
            element  = item.get_attribute(f'{attribute}')
        elif xpath != None:
            if attribute == None:
                element  = item.find_element(By.XPATH, f'{xpath}').text
            else:            
                element  = item.find_element(By.XPATH, f'{xpath}').get_attribute(f'{attribute}')
        return element

    # used in handle_stale_errors
    def retry_element(self,item,item_no,xpath,attribute):
        # wait to reload page
        wait = WebDriverWait(self.driver, 15)
        wait.until(EC.presence_of_element_located((By.XPATH,".//a[@data-testid = 'thumbnail-link']")))
        # xpath of mercari items
        product_items = self.driver.find_elements(By.XPATH, './/a[@data-testid = "thumbnail-link"]')
        item = product_items[item_no]
        # get specific element 
        element = self.get_element(item,xpath,attribute)
        print('back on track')
        return element
                    
    # used to handle any exceptions in generic mercari page scraper
    def handle_stale_errors(self,item,item_no,item_method,item_attribute):
    
        xpath, attribute = self.label_locations(item_method,item_attribute)
        
        try:
            element = self.get_element(item,xpath,attribute)
            return element
                

        except Exception as e:
            print('issue locating element')
            if e == 'StaleElementReferenceException' or 'stale element reference' in str(e):
                print('stale element')
                try:
                    element = self.retry_element(item,item_no,xpath,attribute)
                    print('back on track')
                    return element
                except Exception as e:
                    try:
                        # close and reopen browser
                        self.driver.quit()
                        self.driver = webdriver.Chrome(service=self.service,options=self.chrome_options)
                        self.driver.get(self.current)
                        element = self.retry_element(item,item_no,xpath,attribute)
                        return element
                    except Exception as e:
                        print(f'retried but not working {e}')
            else:
                print('HERE IS E:',e)
        
    # Scrape a single webpage on mercari.jp
    def Scrape_auctions_mercari(self,val):
        
        #temp, will replace when we add in search and cached ids
        last_id = val
        
        # wait for the page to fully load and the dynamic content to be displayed
        wait = WebDriverWait(self.driver, 15)
        wait.until(EC.presence_of_element_located((By.XPATH,".//a[@data-testid = 'thumbnail-link']")))

        # xpath to all auction items
        product_items = self.driver.find_elements(By.XPATH, './/a[@data-testid = "thumbnail-link"]')

        c = 0
        # iterate over the product items and extract the relevant data
        item_method = 'search'
        for item_no,item in enumerate(product_items):
            # find link to item page
            href = self.handle_stale_errors(item,item_no,item_method,item_attribute = 'href')

            if 'shops' in href:
                continue
            
            c+=1
            if last_id == 'empty':
                print(c)
                # get the item id
                href = href.split('item/')[1]
                #href = item.get_attribute('href')
                print("href: ", href)
                
                # get the product title + deal with stale elements
                title = self.handle_stale_errors(item,item_no,item_method,item_attribute = 'title')
                print("Title: ", title.split('のサムネイル')[0])
                
                # get the product price
                price = self.handle_stale_errors(item,item_no,item_method,item_attribute = 'price')
                print("Price: ", price)
            '''else:
                # get the product price
                price = item.find_element(By.XPATH, './/div').text
                print("Price: ", price)
                
                
                # get the product condition
                condition = item.find_element(By.CLASS_NAME, "items-box-condition").text
                print("Condition: ", condition)
                
                # get the product shipping information
                shipping_info = item.find_element(By.CLASS_NAME, "items-box-shipping").text
                print("Shipping Information: ", shipping_info)'''
        rand = random.randint(5,10)
        time.sleep(rand)
            
        
                
                
                
    def next_page_click(self,val):
        
        self.Scrape_auctions_mercari(val)
        # wait on page button to load 
        wait = WebDriverWait(self.driver, 15)
        wait.until(EC.element_to_be_clickable((By.XPATH,'.//div[@data-testid = "pagination-next-button"]/button')))
        # save next page button
        next_page = self.driver.find_elements(By.XPATH,'.//div[@data-testid = "pagination-next-button"]/button')
        self.current = next_page[0].get_attribute('baseURI')
        while len(next_page) >= 1:
            # load next page
            next_page[0].click()
            print('page done')
            # scrape new page
            self.Scrape_auctions_mercari(val)
            # wait on page button to load 
            wait = WebDriverWait(self.driver, 15)
            wait.until(EC.element_to_be_clickable((By.XPATH,'.//div[@data-testid = "pagination-next-button"]/button')))
            # save next page button
            next_page = self.driver.find_elements(By.XPATH,'.//div[@data-testid = "pagination-next-button"]/button')
            self.current = next_page[0].get_attribute('baseURI')
        print('finished')


    def final_func(self):
        
        for key, val in self.dict.items():
            # clean search terms
            key = key.strip().replace(' ', '+')
            
            self.start_search(key)
            
            self.next_page_click(val)
            # close the webdriver
            self.driver.quit()
    
        return self.dict