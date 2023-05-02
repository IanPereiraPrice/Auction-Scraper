/*
resource "aws_s3_bucket" "terraform-state" {

  bucket_prefix = "terraform-state-storage"
  acl    = "private"
}


terraform {
  backend "s3" {
    bucket = <bucket you are storing in(cant reference as a variable)>
    key    = "terraform-state/terraform.tfstate"
    region = <your aws region >
  }
}
*/