variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket for hosting ng-paperless"
}

variable "distribution_id" {
  type        = string
  description = "CloudFront distribution ID used in CI/CD invalidation"
}
