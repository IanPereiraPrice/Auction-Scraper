terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.2.0"
}


variable "aws_secret_key" {

  type      = string
  sensitive = true

}

variable "aws_access_key" {

  type      = string
  sensitive = true

}


provider "aws" {

  region = var.aws_region

  access_key = var.aws_access_key

  secret_key = var.aws_secret_key

}



#resource "random_uuid" "uuid" {}
