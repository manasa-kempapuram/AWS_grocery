provider "aws" {
  region = "eu-north-1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "avatars" {
  bucket = "grocerymate-avatars-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "grocerymate-avatars"
    Environment = "Dev"
  }
}
