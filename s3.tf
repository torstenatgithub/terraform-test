resource "aws_s3_bucket" "S3_Bucket" {
  bucket = "${var.Bucket_Name}"

  tags = {
    Name = "${var.Bucket_Name}"
  }
}
