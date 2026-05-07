# S3 con Lifecycle diferenciado
resource "aws_s3_bucket" "images" {
  bucket = "image-processor-storage-${terraform.workspace}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encrypt" {
  bucket = aws_s3_bucket.images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "rules" {
  bucket = aws_s3_bucket.images.id

  # Regla 1: uploads/ expiran en 30 días
  rule {
    id     = "expire-uploads"
    status = "Enabled"
    filter { prefix = "uploads/" }
    expiration { days = 30 }
  }

  # Regla 2: processed/ expiran en 90 días
  rule {
    id     = "expire-processed"
    status = "Enabled"
    filter { prefix = "processed/" }
    expiration { days = 90 }
  }
}

# SQS Principal con configuración exacta
resource "aws_sqs_queue" "main_queue" {
  name                       = "image-processor-main-queue"
  visibility_timeout_seconds  = 360  # 6x el timeout de la lambda
  message_retention_seconds   = 86400 # 1 día según diagrama
  receive_wait_time_seconds   = 20    # Long Polling
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3 # nMax receives before DLQ
  })
}

resource "aws_sqs_queue" "dlq" {
  name = "image-processor-dlq"
}

# SNS y Alarma de Observabilidad
resource "aws_sns_topic" "alerts" {
  name = "dlq-alerts-topic"
}

resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "dlq-messages-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = { QueueName = aws_sqs_queue.dlq.name }
}