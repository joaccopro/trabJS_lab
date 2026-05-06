
data "archive_file" "upload_zip" {
  type        = "zip"
  source_file = "${path.root}/../src/upload/index.mjs"
  output_path = "${path.module}/upload.zip"
}

data "archive_file" "crop_zip" {
  type        = "zip"
  source_file = "${path.root}/../src/crop/index.mjs"
  output_path = "${path.module}/crop.zip"
}

# ROLES Y PERMISOS (IAM)

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Permiso para Logs (CloudWatch)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Esto permite que las Lambdas lean/escriban en tus recursos
resource "aws_iam_policy" "lambda_aws_services" {
  name        = "lambda-aws-services-policy-${terraform.workspace}"
  description = "Permisos para que las lambdas accedan a S3 y SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject", "s3:GetObject"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::*"] # En producción se limita al ARN del bucket
      },
      {
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_custom_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_aws_services.arn
}


# Lambda Upload 
resource "aws_lambda_function" "upload" {
  function_name = "image-processor-upload-${terraform.workspace}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.upload_zip.output_path
  source_code_hash = data.archive_file.upload_zip.output_base64sha256

  # Le pasamos datos del sistema a la Lambda
  environment {
    variables = {
      BUCKET_NAME = "mi-bucket-de-imagenes-${terraform.workspace}" # Luego lo haremos dinámico
    }
  }

  tags = { Name = "lambda-upload-${terraform.workspace}" }
}

# Lambda Crop
resource "aws_lambda_function" "crop" {
  function_name = "image-processor-crop-${terraform.workspace}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  memory_size = 512
  timeout     = 60

  filename         = data.archive_file.crop_zip.output_path
  source_code_hash = data.archive_file.crop_zip.output_base64sha256

  tags = { Name = "lambda-crop-${terraform.workspace}" }
}