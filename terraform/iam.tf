#------ Managed iam policies to be used 

/*
data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}
data "aws_iam_policy" "AmazonRDSFullAcces" {
  name = "AmazonRDSFullAccess"
}
data "aws_iam_policy" "AmazonSQSFullAccess" {
  name = "AmazonSQSFullAccess"
}
data "aws_iam_policy" "AmazonS3FullAccess" {
  name = "AmazonS3FullAccess"
}
data "aws_iam_policy" "AWSAppSyncPushToCloudWatchLogs" {
  name = "AWSAppSyncPushToCloudWatchLogs"
} 
*/

#------ End of managed iam policies


data "aws_iam_policy" "aws_managed_policies" {
  for_each = var.aws_managed_policies
  name     = each.value
}