#------Variables required for set up


variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

#------End of setup block
#------------------------------------------------

#------Start of s3 variables block


#list of folder names to create in bucket
variable "auction_scraping_folders" {
  description = "list of folders to hold json files to facilitate the lamda fucntion trigger as well as cashing data relevent to scrapes"
  type        = set(string)
  default     = ["search-dict", "store-ids", "ids-to-lambda"]
}

#------End of s3 variables block
#----------------------------------------------------

#------Start of RDS variables block


variable "rds_user_name" {
  description = "postgresql admin password"
  type        = string
}

variable "rds_user_password" {
  description = "postgresql admin password"
  type        = string
}

variable "rds_db_name" {

  type    = string
}

# for sqlAlchemy connection as drivername can be finicky 
variable "rds_drivername" {
  description = "SQL database being used ie: postgres.Used for connection string with sqlalchemy."
  type        = string
  default     = "postgresql"
}
#------End of rds variables block
#------------------------------------

#------Start of Lambda function variables 


#List of all lambda layers to be used
variable "lambda_layer_list" {
  description = "names of the lambda functions to be added to our lambda functions"
  type        = set(string)
  default     = ["scrapy-sqlalchemy-layer"]
}

#List of all lambda functions to be added
variable "lambda_function_list" {
  description = "names of the lambda functions to be added to our lambda functions"
  type        = set(string)
  default     = ["yahoo-item-scraper", "yen-usd"]
}

#List of all AWS Mangaged Policies to be used for apps
variable "aws_managed_policies" {
  description = "List of AWS Mangaged Policies for apps"
  type        = set(string)
  default = [
    "AWSLambdaBasicExecutionRole",
    "AmazonRDSFullAccess",
    "AmazonSQSFullAccess",
    "AmazonS3FullAccess",
    "AWSAppSyncPushToCloudWatchLogs",
  ]
}

# Name of lambda function (use name of folder holding file contents)
# Ensure name matches a name input to lambda_function_list
variable "lambda_function_1" {
  description = "variables needed in order to create a lambda scraper for yahoo_auctions"
  type = object({
    name             = string
    layer_list       = set(string)
    managed_policies = set(string)
  })
  default = {
    name       = "yahoo-item-scraper"
    layer_list = ["scrapy-sqlalchemy-layer"]
    managed_policies = [
      "AWSLambdaBasicExecutionRole",
      "AmazonRDSFullAccess",
      "AmazonSQSFullAccess",
      "AmazonS3FullAccess",
      "AWSAppSyncPushToCloudWatchLogs",
    ]

  }
}

# Name of lambda function (use name of folder holding file contents)
# Ensure name matches a name input to lambda_function_list
variable "lambda_function_2" {
  description = "variables needed in order to create a lambda scraper for yen_usd conversion rate"
  type = object({
    name             = string
    layer_list       = set(string)
    managed_policies = set(string)
  })
  default = {
    name       = "yen-usd"
    layer_list = ["scrapy-sqlalchemy-layer"]
    managed_policies = [
      "AWSLambdaBasicExecutionRole",
      "AmazonRDSFullAccess",
      "AWSAppSyncPushToCloudWatchLogs",
    ]

  }
}