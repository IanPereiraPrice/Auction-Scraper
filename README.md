# Auction-Scraper
Scrapes stored searches on auction site(s) and stores them in rds daily via AWS services
- cost to run is ~ .03-.08 usd per hour on AWS free tier. Airflow struggles to run in a small EC2 instance without crashing, and in short term the medium instance is the only cost to run.

# Current sites scraped
  - https://auctions.yahoo.co.jp/
  # Sites to be added soon
    - mercari.jp 
    - carousell.sg

#Requirements:
  -git
  -github
  -aws account
  -terraform

#Instructions to set up
  # In your AWS account
    -create aws access keys on your aws account
  # In the command line:
    -git clone this repo
    -cd into <Auction-Scraper>/terraform directory 
    -Create .env file with the following contents:
      <Start of the file is line below>
      #!/bin/bash
      export TF_VAR_aws_access_key="your aws public key"
      export TF_VAR_aws_secret_key="your aws secret key"
      export TF_VAR_rds_user_name="<desired username for db>"
      export TF_VAR_rds_user_password="<desired password for db>"
      export TF_VAR_rds_db_name="<desired db_name for db>"
      <End of the file is line above>
      
    - For any specific changes desired, edit the variables in the terraform files. (Not required)
  
    -source .env
    -terraform init
    -terraform apply
    
  # After terraform apply has finished running, go back to AWS account
    # These steps are not neccessary, but to test everything is functioning properly
    - Go to your EC2 instances in AWS and find the Public IPv4 address of the newly created t4g.medium instance and copy the IP address
    - In new tab open paste the IP address with port number 8181, for example: <1.111.11.11:8181>
    - Login to Airflow (username:admin, password:admin)
    - Turn on the dag for a test run and see it run

# After this, can view data on your db using the login information provided in the .env file. Data will continously be updated with daily runs

 - transformed data will be in the dbt_auction_transformed schema

# To add searches to scrape
  - add desired search term to /terraform/s3-files/scraped-search-ids.json
  - add translation or a regex search to japanese_translation table
  - add needed tags to yahoo_auction_tags, and card_classification_table

# Tear Down Infrastrusture

  - Once ready to tear down the infrastucture run terraform destroy in console 
   
    
  






