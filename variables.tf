variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket for hosting ng-paperless"
}

variable "distribution_id" {
  type        = string
  description = "CloudFront distribution ID used in CI/CD invalidation"
}

variable "lightsail_instance_name" {
  type        = string
  default     = "paperless-backend"
  description = "Name for the Lightsail instance"
}

variable "lightsail_availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "Availability Zone for the Lightsail instance"
}

variable "lightsail_key_pair_name" {
  type        = string
  description = "The name of the Lightsail SSH key pair (must be pre-created in AWS)"
}

