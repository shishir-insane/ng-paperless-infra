output "bucket_name" {
  description = "The name of the created S3 bucket"
  value       = aws_s3_bucket.ng_paperless.bucket
}

output "cloudfront_url" {
  description = "The URL of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}