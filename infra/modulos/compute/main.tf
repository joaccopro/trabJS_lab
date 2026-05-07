# IAM Roles con nombres exactos del diagrama
resource "aws_iam_role" "upload_role" {
  name = "upload-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Permisos Scoped (Mínimo Privilegio)
resource "aws_iam_role_policy" "upload_s3_limited" {
  name = "s3-upload-only"
  role = aws_iam_role.upload_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "s3:PutObject"
      Effect   = "Allow"
      Resource = "arn:aws:s3:::image-processor-storage-*/uploads/*"
    }]
  })
}

# Lambda UPLOAD (256MB / 30s)
resource "aws_lambda_function" "upload" {
  function_name = "upload-lambda"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.upload_role.arn
  handler       = "index.handler"
  memory_size   = 256
  timeout       = 30

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.lambda_sg_id]
  }
}

# Lambda CROP (512MB / 60s)
resource "aws_lambda_function" "crop" {
  function_name = "crop-lambda"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.crop_role.arn # (Repetir lógica similar para crop_role)
  handler       = "index.handler"
  memory_size   = 512
  timeout       = 60

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.lambda_sg_id]
  }
}