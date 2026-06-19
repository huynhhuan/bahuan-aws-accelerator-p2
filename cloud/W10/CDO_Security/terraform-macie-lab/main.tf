provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# 1. Macie is already enabled manually in the console

# 2. S3 Bucket
resource "aws_s3_bucket" "macie_lab_bucket" {
  bucket        = var.bucket_name
  force_destroy = true # Allows deleting the bucket even if it contains objects
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.macie_lab_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. Upload Sample Data to S3
resource "aws_s3_object" "sample_pii_data" {
  bucket       = aws_s3_bucket.macie_lab_bucket.id
  key          = "macie_sample_data_large.csv"
  source       = "${path.module}/../macie_sample_data_large.csv"
  content_type = "text/csv"
}

# 4. SNS Topic
resource "aws_sns_topic" "macie_alerts" {
  name = "Macie-Alerts-Topic-TF"
}

# Grant EventBridge permission to publish to the SNS Topic
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.macie_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.macie_alerts.arn
      }
    ]
  })
}

# Subscribe email to SNS Topic
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.macie_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 5. EventBridge Rule for Macie Findings
resource "aws_cloudwatch_event_rule" "macie_finding_rule" {
  name        = "Trigger-Macie-Alert-Rule-TF"
  description = "Capture Macie findings and send to SNS"

  event_pattern = jsonencode({
    source      = ["aws.macie2"]
    "detail-type" = ["Macie Finding"]
  })
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.macie_finding_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.macie_alerts.arn
}

# 6. Macie Classification Job
resource "aws_macie2_classification_job" "scan_job" {
  name        = "Scan-PII-Data-Job-TF"
  job_type    = "ONE_TIME"
  job_status  = "RUNNING"
  
  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [aws_s3_bucket.macie_lab_bucket.bucket]
    }
  }

  depends_on = [
    aws_s3_object.sample_pii_data
  ]
}
