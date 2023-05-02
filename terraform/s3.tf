resource "aws_s3_bucket" "scraping-bucket" {

  bucket_prefix = "auction-scraping-files-"

}


resource "aws_s3_object" "auction-folders" {

  for_each = var.auction_scraping_folders

  bucket = aws_s3_bucket.scraping-bucket.id

  key = "${each.value}/"
}

resource "aws_s3_object" "scraped-search-ids" {

  bucket = aws_s3_bucket.scraping-bucket.id

  key = "search-dict/scraped-search-ids.json"

  source = "${path.module}/s3-files/scraped-search-ids.json"


}

resource "aws_s3_bucket" "lambda-bucket" {

  bucket_prefix = "lambda-files-"

  force_destroy = true

}
