resource "aws_s3_bucket" "images" {
  bucket        = "image-processor-${terraform.workspace}-images-bucket"
  force_destroy = true
  tags          = { Name = "s3-images-${terraform.workspace}" }
}

resource "aws_s3_bucket_public_access_block" "images_private" {
  bucket                  = aws_s3_bucket.images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images_crypto" {
  bucket = aws_s3_bucket.images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "images_lifecycle" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expire-uploads"
    status = "Enabled"
    filter { prefix = "uploads/" }
    expiration { days = 30 }
  }

  rule {
    id     = "expire-processed"
    status = "Enabled"
    filter { prefix = "processed/" }
    expiration { days = 90 }
  }
}

resource "aws_sqs_queue" "dlq" {
  name                      = "image-processor-${terraform.workspace}-image-dlq"
  message_retention_seconds = 1209600 # 14 días en segundos
  tags                      = { Name = "sqs-dlq-${terraform.workspace}" }
}

resource "aws_sqs_queue" "main_queue" {
  name                       = "image-processor-${terraform.workspace}-image-queue"
  visibility_timeout_seconds = 360   # 6x Lambda timeout (según diagrama)
  message_retention_seconds  = 86400 # 1 día en segundos
  receive_wait_time_seconds  = 20    # Long polling

  # Conexión con la DLQ (Max 3 intentos)
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Name = "sqs-main-${terraform.workspace}" }
}

resource "aws_sqs_queue_policy" "s3_to_sqs" {
  queue_url = aws_sqs_queue.main_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main_queue.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" : aws_s3_bucket.images.arn }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn     = aws_sqs_queue.main_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }

  depends_on = [aws_sqs_queue_policy.s3_to_sqs]
}