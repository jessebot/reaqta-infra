terraform {
  backend "s3" {
    bucket = "areallycoolstatebucket"
    key    = "reaqta-challenge"
    region = "eu-central-1"
  }
}

