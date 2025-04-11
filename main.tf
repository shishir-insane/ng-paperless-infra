provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "ng_paperless" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "ng_paperless_site" {
  bucket = aws_s3_bucket.ng_paperless.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.ng_paperless.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.ng_paperless.arn}/*"
    }]
  })
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket.ng_paperless.website_endpoint
    origin_id   = "s3-ng-paperless"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-ng-paperless"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_lightsail_instance" "paperless_backend" {
  name              = var.lightsail_instance_name
  availability_zone = var.lightsail_availability_zone
  blueprint_id      = "ubuntu_22_04"
  bundle_id         = "nano_2_0"  # 512 MB RAM, upgrade if needed
  key_pair_name     = var.lightsail_key_pair_name

  user_data = file("${path.module}/scripts/lightsail-init.sh")

  tags = {
    Name = "paperless-backend"
  }
}

resource "aws_lightsail_static_ip" "paperless_ip" {
  name = "${var.lightsail_instance_name}-ip"
}

resource "aws_lightsail_static_ip_attachment" "attach_ip" {
  instance_name = aws_lightsail_instance.paperless_backend.name
  static_ip_name = aws_lightsail_static_ip.paperless_ip.name
}
