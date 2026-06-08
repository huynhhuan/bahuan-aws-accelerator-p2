data "aws_iam_policy_document" "web_assets_read_only" {
  statement {
    sid = "ListAssetsBucket"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      module.assets_bucket.s3_bucket_arn,
    ]
  }

  statement {
    sid = "ReadAssetsObjects"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${module.assets_bucket.s3_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_policy" "web_assets_read_only" {
  name        = "${local.name_prefix}-assets-read-only"
  description = "Allow the web server to read static assets from S3"
  policy      = data.aws_iam_policy_document.web_assets_read_only.json

  tags = local.common_tags
}

