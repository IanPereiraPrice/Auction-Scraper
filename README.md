# Auction-Scraper
Scrapes stored searches on auction site(s) and stores them in rds daily via AWS services

#Requirements:
-git
-github
-aws account
-terraform

#Instructions to set up
-create aws access keys on your aws account
-git clone this repo
-cd into <Auction-Scraper>/terraform 
- Create .env file with the following contents:{


#!/bin/bash
export TF_VAR_aws_access_key="your aws public key"
export TF_VAR_aws_secret_key="your aws secret key"
export TF_VAR_rds_user_name="<desired username for db>"
export TF_VAR_rds_user_password="<desired password for db>"
export TF_VAR_rds_db_name="<desired db_name for db>"}

-source .env
-terraform init
-terraform apply




