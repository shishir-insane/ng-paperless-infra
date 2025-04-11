resource "aws_iam_user" "github_ci_user" {
  name = "github-ng-paperless-deployer"
}

resource "aws_iam_access_key" "github_ci_key" {
  user = aws_iam_user.github_ci_user.name
}

resource "aws_iam_policy" "github_ci_policy" {
  name        = "NgPaperlessDeployPolicy"
  description = "Allows CI/CD to deploy Angular build to S3 and invalidate CloudFront"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "S3DeployAccess",
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        Sid = "CloudFrontInvalidation",
        Effect = "Allow",
        Action = "cloudfront:CreateInvalidation",
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.distribution_id}"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_policy" {
  user       = aws_iam_user.github_ci_user.name
  policy_arn = aws_iam_policy.github_ci_policy.arn
}

data "aws_caller_identity" "current" {}

output "ci_access_key_id" {
  value       = aws_iam_access_key.github_ci_key.id
  description = "Use this in GitHub Actions as AWS_ACCESS_KEY_ID"
  sensitive   = false
}

output "ci_secret_access_key" {
  value       = aws_iam_access_key.github_ci_key.secret
  description = "Use this in GitHub Actions as AWS_SECRET_ACCESS_KEY"
  sensitive   = true
}
