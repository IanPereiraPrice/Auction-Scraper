# Create zip of all lambda function
data "archive_file" "lambda_function_zips" {
  for_each    = var.lambda_function_list
  type        = "zip"
  source_dir  = "${path.module}/lambda/${each.value}/"
  output_path = "${path.module}/lambda/artifacts/${each.value}.zip"
}

# Add zips to lambda bucket
resource "aws_s3_object" "lambda_code" {
  for_each    = var.lambda_function_list
  bucket      = aws_s3_bucket.lambda-bucket.id
  key         = "lambda-functions/${each.value}.zip"
  source      = data.archive_file.lambda_function_zips[each.value].output_path
  source_hash = data.archive_file.lambda_function_zips[each.value].output_base64sha256
}

# Add Lambda layer zip file to lambda bucket
resource "aws_s3_object" "lambda-layers" {
  for_each = var.lambda_layer_list
  bucket   = aws_s3_bucket.lambda-bucket.id
  key      = "lambda-layers/${each.value}.zip"
  source   = "${path.module}/lambda/artifacts/${each.value}.zip"
}
# Create the Lambda layer
resource "aws_lambda_layer_version" "lambda-layers" {
  for_each   = var.lambda_layer_list
  s3_bucket  = aws_s3_bucket.lambda-bucket.id
  s3_key     = aws_s3_object.lambda-layers[each.value].id
  layer_name = each.value
}

# Declare the Lambda function (Customize, not iterable)
resource "aws_lambda_function" "lambda-yahoo-function" {
  function_name = var.lambda_function_1.name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {

      user       = var.rds_user_name
      passwd     = var.rds_user_password
      db_name    = var.rds_db_name
      port       = aws_db_instance.prod-postgres-db.port
      host       = aws_db_instance.prod-postgres-db.address
      drivername = var.rds_drivername
    }
  }
  timeout = 300
  layers = [
    for layer in var.lambda_function_1.layer_list : aws_lambda_layer_version.lambda-layers[layer].arn
  ]
  s3_bucket = aws_s3_bucket.lambda-bucket.id
  s3_key    = trimprefix(aws_s3_object.lambda_code[var.lambda_function_1.name].key, "./")

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_s3_object.lambda_code,
    aws_cloudwatch_log_group.example,
    aws_db_instance.prod-postgres-db,
  ]

}

# ------ testing block




#TESTING to see if fix issue
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ------ testing block end 




# Create Lambda trigger off of s3
# note to self: add lambda layers into vars to make more generic
resource "aws_s3_bucket_notification" "yahoo-scraper-trigger" {

  bucket = aws_s3_bucket.scraping-bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda-yahoo-function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "ids-to-lambda/"
    filter_suffix       = ".json"
  }
  # Important to avoid errors. Want triggers to be built after Lambda function
  depends_on = [aws_lambda_permission.allow_bucket]
}

#Add permission to s3 bucket to trigger this lambda function
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-yahoo-function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.scraping-bucket.id}"
  # Important to avoid errors. Want triggers to be built after Lambda function
  depends_on = [aws_lambda_function.lambda-yahoo-function]
}

# Declare the IAM role for the Lambda function
resource "aws_iam_role" "iam_for_lambda" {
  name = var.lambda_function_1.name

  managed_policy_arns = compact([
    for x in var.lambda_function_1.managed_policies : data.aws_iam_policy.aws_managed_policies[x].arn

  ])


  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  depends_on         = [data.aws_iam_policy.aws_managed_policies]
}

# Declare IAM policy for the Lambda's IAM role
resource "aws_iam_policy" "lambda_policy" {
  name   = "scraper-lambda-policy"
  policy = file("./policy/lambda_function_policy.json")
}


#------Lambda Function no.2
resource "aws_lambda_function" "yen-usd-function" {
  function_name = var.lambda_function_2.name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {

      user       = var.rds_user_name
      passwd     = var.rds_user_password
      db_name    = var.rds_db_name
      port       = aws_db_instance.prod-postgres-db.port
      host       = aws_db_instance.prod-postgres-db.address
      drivername = var.rds_drivername
    }
  }
  timeout = 30
  layers = [
    for layer in var.lambda_function_2.layer_list : aws_lambda_layer_version.lambda-layers[layer].arn
  ]
  s3_bucket = aws_s3_bucket.lambda-bucket.id
  s3_key    = trimprefix(aws_s3_object.lambda_code[var.lambda_function_2.name].key, "./")

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_s3_object.lambda_code,
    aws_cloudwatch_log_group.example,
    aws_db_instance.prod-postgres-db,
  ]

}

# Declare the IAM role for the Lambda function
resource "aws_iam_role" "iam_for_lambda_2" {
  name = var.lambda_function_2.name

  managed_policy_arns = compact([
    for x in var.lambda_function_2.managed_policies : data.aws_iam_policy.aws_managed_policies[x].arn

  ])


  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  depends_on         = [data.aws_iam_policy.aws_managed_policies]
}

#Create cron job for yen-usd
module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  rules = {
    crons = {
      description         = "daily job to scrape the current yen-usd conversion ratio"
      schedule_expression = "cron(0 04 * * ? *)"
    }
  }

  targets = {
    crons = [
      {
        name = "${var.lambda_function_2.name} daily scheduler"
        arn  = aws_lambda_function.yen-usd-function.arn

      }
    ]
  }
}

/*
resource "aws_scheduler_schedule" "yen_usd" {
  description = "daily job to scrape the current yen-usd conversion ratio"
  name = "${var.lambda_function_2.name} daily scheduler"

  flexible_time_window {
    mode = "FLEXIBLE"
    maximum_window_in_minutes = 15

  }

  schedule_expression = "rate(24 hour)"
  start_date = "2023-01-01T04:30:00Z" 
  target = {
    arn = aws_lambda_function.yen-usd-function.arn
    role_arn = 

  }
}
*/

/*
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "${aws_lambda_function.yen-usd-function.arn}:*",
                "{aws_lambda_function.yen-usd-function.arn}"
            ]
        }
    ]
}
*/
