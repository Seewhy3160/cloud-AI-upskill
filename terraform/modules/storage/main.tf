# ---------------------------------------------------------------------------
# STORAGE: S3 video-content bucket with versioning, KMS encryption, blocked
# public access, and a lifecycle policy that tiers cold content to cheaper
# storage and archives viewing-history data after 2 years.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "content" {
  bucket = var.bucket_name
  tags   = merge(var.tags, { Name = "${var.name_prefix}-content" })
}

resource "aws_s3_bucket_versioning" "content" {
  bucket = aws_s3_bucket.content.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "content" {
  bucket = aws_s3_bucket.content.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "content" {
  bucket                  = aws_s3_bucket.content.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "content" {
  bucket = aws_s3_bucket.content.id

  # Tier cold video content to cheaper storage classes over time.
  rule {
    id     = "tier-cold-content"
    status = "Enabled"
    filter {}
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  # Archive viewing-history exports (prefixed) after 2 years.
  rule {
    id     = "archive-viewing-history"
    status = "Enabled"
    filter {
      prefix = "viewing-history/"
    }
    transition {
      days          = 730
      storage_class = "DEEP_ARCHIVE"
    }
  }
}
